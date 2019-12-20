require 'nokogiri'
require 'orcid_client'

class Claim < ActiveRecord::Base
  # include view helpers
  include ActionView::Helpers::TextHelper

  # include helper module for DOI resolution
  include Resolvable

  # include helper module for date and time calculations
  include Dateable

  # include helper module for author name parsing
  include Authorable

  # include helper module for work type
  include Typeable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  SUBJECT = "Add your published work(s) to your ORCID record"
  INTRO =  "Hello, You may not be familiar with DataCite. Our data centers send us publication information (including ORCID iDs and DOIs), and we ensure that your work can be found, linked and cited. It looks like you have included your ORCID iD with a recent publication submission and that has been passed to us by your data center. We would like to auto-update your ORCID record with information about these published work(s) published, starting today with those listed below, so you don’t have to search for and add them manually, now or in the future. Please click ‘Grant permissions’ below to set this up."

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  after_commit :queue_claim_job, on: [:create, :update]

  validates :orcid, :doi, :source_id, presence: true

  delegate :uid, to: :user, allow_nil: true
  delegate :orcid_token, to: :user, allow_nil: true

  alias_attribute :state, :aasm_state

  aasm whiny_transitions: false do
    # waiting is initial state for new claims
    state :waiting, initial: true
    state :working, :failed, :done, :ignored, :deleted, :notified

    event :start do
      transitions from: [:waiting, :ignored, :deleted, :notified], to: :working
    end

    event :finish do
      transitions from: [:working], to: :deleted, if: [:to_be_deleted?]
      transitions from: [:waiting, :working, :failed], to: :done
    end

    event :notify do
      transitions from: [:working], to: :notified
    end

    event :error do
      transitions from: [:waiting, :working, :ignored, :deleted, :notified], to: :failed
    end

    event :skip do
      transitions from: [:waiting, :working, :failed, :deleted, :notified], to: :ignored
    end
  end

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at
  alias_attribute :claimed, :claimed_at
  alias_attribute :user_id, :orcid

  scope :by_state, ->(state) { where(aasm_state: state) }
  scope :waiting, -> { by_state("waiting") }
  scope :working, -> { by_state("working") }
  scope :failed, -> { by_state("failed") }
  scope :done, -> { by_state("done") }
  scope :ignored, -> { by_state("ignored") }
  scope :deleted, -> { by_state("deleted") }
  scope :notified, -> { by_state("notified") }
  scope :stale, -> { where(aasm_state: ["waiting", "working"])}
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  scope :q, ->(query) { where("doi like ?", "%#{query}%") }
  scope :search_and_link, -> { where(source_id: "orcid_search").where("claimed_at IS NOT NULL") }
  scope :auto_update, -> { where(source_id: "orcid_update").where("claimed_at IS NOT NULL") }
  scope :total_count, -> { where(claim_action: "create").count }

  serialize :error_messages, JSON

  # use different index for testing
  index_name Rails.env.test? ? "claims-test" : "claims"

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: 'keyword', filter: %w(lowercase ascii_folding) }
      },
      filter: { ascii_folding: { type: 'asciifolding', preserve_original: true } }
    }
  } do
    mapping dynamic: 'false' do
      indexes :id,            type: :keyword
      indexes :uuid,          type: :keyword
      indexes :doi,           type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :user_id,       type: :keyword
      indexes :source_id,     type: :keyword
      indexes :error_messages, type: :text
      indexes :claim_action,  type: :keyword
      indexes :put_code,      type: :keyword
      indexes :state_number,  type: :integer
      indexes :aasm_state,    type: :keyword
      indexes :claimed,       type: :date
      indexes :created,       type: :date
      indexes :updated,       type: :date

      # include parent objects
      indexes :user,          type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}},
        given_names: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}},
        family_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}},
        github: { type: :keyword },
        claimed: { type: :date },
        created: { type: :date },
        updated: { type: :date },
        is_active: { type: :boolean }
      }
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(options={})
    {
      "id" => uuid,
      "uuid" => uuid,
      "doi" => doi,
      "user_id" => orcid,
      "source_id" => source_id,
      "error_messages" => error_messages,
      "claim_action" => claim_action,
      "put_code" => put_code,
      "state_number" => state_number,
      "aasm_state" => aasm_state,
      "claimed" => claimed,
      "created" => created,
      "updated" => updated,
      "user" => user,
    }
  end

  def self.query_fields
    ['uuid^10', 'doi^5', 'orcid^5', 'source_id^5', '_all']
  end

  def self.query_aggregations
    {
      created: { date_histogram: { field: 'created', interval: 'year', min_doc_count: 1 } },
      sources: { terms: { field: 'source_id', size: 10, min_doc_count: 1 } },
      users: { terms: { field: 'user_id', size: 10, min_doc_count: 1 } },
      claim_actions: { terms: { field: 'claim_action', size: 10, min_doc_count: 1 } },
      states: { terms: { field: 'aasm_state', size: 10, min_doc_count: 1 } }
    }
  end

  def to_be_created?
    claim_action == "create"
  end

  def to_be_deleted?
    claim_action == "delete"
  end

  def queue_claim_job
    ClaimJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def process_data(options = {})
    self.start

    ### depdency Injection for testing
    result = options[:collect_data] || collect_data 

    if result.body["skip"]
      self.finish! && return if claimed_at.present?

      logger.info "[Skipped] #{self.uid} – #{self.doi}] #{result.body['reason']}"

      self.skip
    elsif result.body["errors"]
      write_attribute(:error_messages, result.body["errors"].inspect)

      # send notification to Sentry
      Raven.capture_exception(RuntimeError.new(result.body["errors"].first["title"])) if ENV["SENTRY_DSN"]

      logger.error "[Error] #{self.uid} – #{self.doi}] " + result.body["errors"].first["title"].inspect

      self.error!
    elsif result.body["notification"]
      write_attribute(:put_code, result.body["put_code"])
      write_attribute(:error_messages, nil)

      logger.error "[Notification] #{self.uid} – #{self.doi}] with Put Code #{result.body["put_code"]}" 

      self.notify
    else
      if to_be_created?
        write_attribute(:claimed_at, Time.zone.now)
        write_attribute(:put_code, result.body["put_code"])
        write_attribute(:error_messages, nil)

        logger.info "[Done] #{self.uid} – #{self.doi}] with Put Code #{result.body["put_code"]}" 
      elsif to_be_deleted?
        write_attribute(:claimed_at, nil)
        write_attribute(:put_code, nil)
        write_attribute(:error_messages, nil)

        logger.info "[Deleted] #{self.uid} – #{self.doi}] with Put Code #{result.body["put_code"]}" 
      end

      self.finish!
    end
  end

  def collect_data(options={})
    # already claimed
    return OpenStruct.new(body: { "skip" => true, "Reason" => "already claimed." }) if to_be_created? && claimed_at.present?

    # user has not signed up yet or orcid_token is missing
    if (user.blank? || orcid_token.blank?)
      if ENV['NOTIFICATION_ACCESS_TOKEN'].present?
        response = notification.create_notification(options)
        response.body["notification"] = true
        return response
      else
        return OpenStruct.new(body: { "skip" => true, "reason" => "No user and/or ORCID token" })
      end
    end

    # user has not given permission for auto-update
    return OpenStruct.new(body: { "skip" => true, "reason" => "No auto-update permission" }) if source_id == "orcid_update" && user && !user.auto_update

    # user has too many claims already
    return OpenStruct.new(body: { "skip" => true, "reason" => "Too many claims. Only 10,000 claims allowed." }) if user.claims.total_count > 10000

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if work.data.nil?

    # validate data
    return OpenStruct.new(body: { "errors" => work.validation_errors.map { |error| { "title" => error } }}) if work.validation_errors.present?

    options[:sandbox] = (ENV["ORCID_URL"] == "https://sandbox.orcid.org")

    # create or delete entry in ORCID record
    if to_be_created?
      work.create_work(options)
    elsif to_be_deleted?
      work.delete_work(options)
    end
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def work
    Work.new(doi: doi, orcid: orcid, orcid_token: orcid_token, put_code: put_code)
  end

  def notification
    Notification.new(doi: doi, orcid: orcid, notification_access_token: ENV['NOTIFICATION_ACCESS_TOKEN'], put_code: put_code, subject: SUBJECT, intro: INTRO)
  end

  def without_control(s)
    r = ""
    s.each_codepoint do |c|
      if c >= 32
        r << c
      end
    end
    r
  end
end
