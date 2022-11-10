# frozen_string_literal: true

require "nokogiri"
require "orcid_client"

class Claim < ApplicationRecord
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
  INTRO = "Hello, You may not be familiar with DataCite. Our data centers send us publication information (including ORCID iDs and DOIs), and we ensure that your work can be found, linked and cited. It looks like you have included your ORCID iD with a recent publication submission and that has been passed to us by your data center. We would like to auto-update your ORCID record with information about these published work(s) published, starting today with those listed below, so you don’t have to search for and add them manually, now or in the future. Please click ‘Grant permissions’ below to set this up."

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  before_validation :set_defaults

  validates :orcid, :doi, :source_id, presence: true

  delegate :uid, to: :user, allow_nil: true
  delegate :orcid_token, to: :user, allow_nil: true

  alias_attribute :state, :aasm_state

  aasm whiny_transitions: false do
    # waiting is initial state for new claims
    state :waiting, initial: true
    state :working, :failed, :done, :ignored, :deleted, :notified

    event :start do
      transitions from: %i[waiting ignored deleted notified], to: :working
    end

    event :finish do
      transitions from: %i[working done], to: :deleted, if: :to_be_deleted?
      transitions from: %i[waiting working failed], to: :done, unless: :to_be_deleted?
    end

    event :notify do
      transitions from: [:working], to: :notified
    end

    event :error do
      transitions from: %i[waiting working ignored deleted notified], to: :failed
    end
  end

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at
  alias_attribute :claimed, :claimed_at
  alias_attribute :user_id, :orcid

  scope :by_state, ->(state) { where(aasm_state: state) }
  # scope :waiting, -> { by_state("waiting") }
  # scope :working, -> { by_state("working") }
  # scope :failed, -> { by_state("failed") }
  # scope :done, -> { by_state("done") }
  # scope :ignored, -> { by_state("ignored") }
  # scope :deleted, -> { by_state("deleted") }
  # scope :notified, -> { by_state("notified") }
  scope :stale, -> { where(aasm_state: ["waiting", "working"]) }
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
        string_lowercase: { tokenizer: "keyword", filter: %w(lowercase ascii_folding) },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w(lowercase) },
      },
      filter: { ascii_folding: { type: "asciifolding", preserve_original: true } },
    },
  } do
    mapping dynamic: "false" do
      indexes :id,            type: :keyword
      indexes :uuid,          type: :keyword
      indexes :doi,           type: :keyword, normalizer: "keyword_lowercase"
      indexes :user_id,       type: :keyword
      indexes :source_id,     type: :keyword
      indexes :error_messages, type: :object, properties: {
        status: { type: :integer },
        title: { type: :text },
      }
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
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        given_names: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        family_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        github: { type: :keyword },
        claimed: { type: :date },
        created: { type: :date },
        updated: { type: :date },
        is_active: { type: :boolean },
      }
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(_options = {})
    {
      "id" => uuid,
      "uuid" => uuid,
      "doi" => doi.downcase,
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
      "user" => user
    }
  end

  def self.query_fields
    ["uuid^10", "doi^5", "orcid^5", "source_id^5", "_all"]
  end

  def self.query_aggregations
    {
      created: { date_histogram: { field: "created", interval: "year", min_doc_count: 1 } },
      sources: { terms: { field: "source_id", size: 10, min_doc_count: 1 } },
      users: { terms: { field: "user_id", size: 10, min_doc_count: 1 } },
      claim_actions: { terms: { field: "claim_action", size: 10, min_doc_count: 1 } },
      states: { terms: { field: "aasm_state", size: 10, min_doc_count: 1 } },
    }
  end

  def to_be_created?
    claim_action == "create"
  end

  def to_be_deleted?
    claim_action == "delete"
  end

  def queue_claim_job
    logger.info "[Queue] #{uid} – #{doi}: Queued for claiming"
    ClaimJob.perform_later(self)
  end

  def to_param # overridden, use uuid instead of id
    uuid
  end

  def process_data(options = {})
    start

    result = collect_data

    if result.body["errors"]
      update_column(:error_messages, format_error_message(result.body["errors"]))

      logger.error "[Error] #{uid} – #{doi}: #{format_error_message(result.body["errors"]).inspect}"

      error!
    elsif result.body["notification"]
      update_column(put_code: result.body["put_code"],
                        error_messages: [])

      logger.error "[Notification] #{uid} – #{doi} with Put Code #{result.body['put_code']}"

      notify
    else
      if to_be_created?
        to_update = {
          claimed_at: Time.zone.now,
          error_messages: []
        }

        if result.body["put_code"].present?
          to_update[:put_code] = result.body["put_code"]
        end

        update_columns(to_update)

        logger.info "[Done] #{uid} – #{doi} with Put Code #{result.body['put_code']}"
      elsif to_be_deleted?
        update_columns(claimed_at: nil,
                          put_code: nil,
                          error_messages: [])

        logger.info "[Deleted] #{uid} – #{doi}"
      end

      finish!
    end
  end

  def collect_data(options = {})
    # user has not signed up yet or orcid_token is missing
    if user.blank? || orcid_token.blank?
      if ENV["NOTIFICATION_ACCESS_TOKEN"].present?
        response = notification.create_notification(options)
        response.body["notification"] = true
        return response
      else
        return OpenStruct.new(body: { "errors" => [{ "title" => "No user and/or ORCID token" }] })
      end
    end

    # user has not given permission for auto-update
    return OpenStruct.new(body: { "errors" => [{ "title" => "No auto-update permission" }] }) if source_id == "orcid_update" && user && !user.auto_update

    # user has too many claims already
    return OpenStruct.new(body: { "errors" => [{ "title" => "Too many claims. Only 10,000 claims allowed." }] }) if user.claims.total_count > 10000

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if work.data.nil?

    # orcid_token has expired, but is not default 1970-01-01
    return OpenStruct.new(body: { "errors" => [{ "status" => 401, "title" => "token has expired." }] }) if (Date.new(1970, 1, 2).beginning_of_day..Date.today.end_of_day) === user.orcid_expires_at

    # Don't go to orcid if we've got a claimed_at date but marked as still to create with no put_code
    # return OpenStruct.new(body: { "skip" => true, "reason" => "Already claimed." }) if to_be_created? && !put_code.present? && claimed_at.present?

    # validate data
    return OpenStruct.new(body: { "errors" => work.validation_errors.map { |error| { "title" => error } } }) if work.validation_errors.present?

    options[:sandbox] = ENV["SANDBOX"].present? || (ENV["ORCID_URL"] == "https://sandbox.orcid.org")

    # create or delete entry in ORCID record. If put_code exists, update entry
    if to_be_created? && put_code.present?
      logger.info "Claim #{uid} – #{doi} updated."
      work.update_work(options)
    elsif to_be_created?
      logger.info "Claim #{uid} – #{doi} created."
      work.create_work(options)
    elsif to_be_deleted?
      logger.info "Claim #{uid} – #{doi} deleted."
      work.delete_work(options)
    end
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def work
    sandbox = ENV["SANDBOX"].present? || (ENV["ORCID_URL"] == "https://sandbox.orcid.org")
    # Note that if this is ever intended in future to support claiming for non datacite dois
    # Then we will need to change following to be looked up from a better location
    agency = "datacite"
    Work.new(doi: doi, orcid: orcid.upcase, orcid_token: orcid_token, put_code: put_code, sandbox: sandbox, agency: agency)
  end

  def notification
    Notification.new(doi: doi, orcid: orcid.upcase, notification_access_token: ENV["NOTIFICATION_ACCESS_TOKEN"], put_code: put_code, subject: SUBJECT, intro: INTRO)
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

  def self.import_by_ids(options = {})
    from_id = (options[:from_id] || Claim.minimum(:id)).to_i
    until_id = (options[:until_id] || Claim.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      ClaimImportByIdJob.perform_later(options.merge(id: id))
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index = if Rails.env.test?
      "claims-test"
    elsif options[:index].present?
      options[:index]
    else
      inactive_index
    end
    errors = 0
    count = 0

    Claim.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |claims|
      response = Claim.__elasticsearch__.client.bulk \
        index: index,
        type: Claim.document_type,
        body: claims.map { |claim| { index: { _id: claim.id, data: claim.as_indexed_json } } }

      # try to handle errors
      response["items"].select { |k, _v| k.values.first["error"].present? }.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
        id = item.dig("index", "_id").to_i
        claim = Claim.where(id: id).first
        IndexJob.perform_later(claim) if claim.present?
      end

      count += claims.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} claims with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} claims with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => e
    Rails.logger.error "[Elasticsearch] Error #{e.message} importing claims with IDs #{id} - #{(id + 499)}."

    count = 0

    Claim.where(id: id..(id + 499)).find_each do |claim|
      IndexJob.perform_later(claim)
      count += 1
    end

    count
  end

  def format_error_message(messages)
    Array.wrap(messages) do |msg|
      if msg["title"].is_a?(Hash) && msg.dig("title", "developer-message").present?
        title = msg.dig("title", "developer-message")
      elsif msg["title"].is_a?(String)
        title = msg.dig("title")
      else
        msg = nil
      end

      { status: msg["status"] || 400, title: title }
    end
  end

  private
    def set_defaults
      self.claim_action = "create" if claim_action.blank?

      self.error_messages = format_error_message(error_messages)
    end
end
