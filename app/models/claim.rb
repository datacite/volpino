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

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  after_commit :queue_claim_job, on: [:create, :update], if: Proc.new { |claim| claim.waiting? }

  validates :orcid, :doi, :source_id, presence: true

  delegate :uid, to: :user
  delegate :access_token, to: :user

  state_machine :initial => :waiting do
    state :waiting, value: 0
    state :working, value: 1
    state :failed, value: 2
    state :done, value: 3
    state :ignored, value: 4

    event :start do
      transition [:waiting] => :working
      transition any => same
    end

    event :finish do
      transition [:working] => :done
      transition any => same
    end

    event :error do
      transition any => :failed
    end

    event :skip do
      transition any => :ignored
    end
  end

  scope :by_state, ->(state) { where("state = ?", state) }
  scope :order_by_date, -> { order("claimed_at DESC") }

  scope :waiting, -> { by_state(0).order_by_date }
  scope :working, -> { by_state(1).order_by_date }
  scope :failed, -> { by_state(2).order_by_date }
  scope :done, -> { by_state(3).order_by_date }
  scope :ignored, -> { by_state(4).order_by_date }
  scope :stale, -> { where("state < 2").order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  scope :query, ->(query) { where("doi like ?", "%#{query}%") }
  scope :search_and_link, -> { where(source_id: "orcid_search").where("claimed_at IS NOT NULL") }
  scope :auto_update, -> { where(source_id: "orcid_update").where("claimed_at IS NOT NULL") }
  scope :total_count, -> { where(claim_action: "create").count }

  serialize :error_messages, JSON

  def queue_claim_job
    ClaimJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  # push to deposit API if no error and we have collected works
  def lagotto_post
    Maremma.post ENV['ORCID_UPDATE_URL'], data: deposit.to_json,
                                          token: ENV['ORCID_UPDATE_TOKEN'],
                                          content_type: 'json'
  end

  def process_data(options={})
    self.start
    if collect_data["errors"]
      write_attribute(:error_messages, collect_data["errors"])

      # send notification to Bugsnag
      if ENV['BUGSNAG_KEY']
        Bugsnag.notify(RuntimeError.new(collect_data["errors"].first["title"]))
      end

      self.error
    elsif collect_data["data"]
      update_attributes(claimed_at: Time.zone.now, put_code: collect_data["put_code"])
      lagotto_post
      self.finish
    else
      self.skip
    end
  end

  def collect_data
    # already claimed
    return { "data" => work.data } if claimed_at.present?

    # user has not signed up yet or access_token is missing
    return {} unless user.present? && user.access_token.present?

    # user has not given permission for auto-update
    return {} if source_id == "orcid_update" && user && !user.auto_update

    # user has too many claims already
    return { "errors" => [{ "title" => "Too many claims. Only 18,000 claims allowed." }] } if user.claims.total_count > 18000

    # missing data raise errors
    return { "errors" => [{ "title" => "Missing data" }] } if work.data.nil?

    # validate data
    return { "errors" => work.validation_errors.map { |error| { "title" => error } }} if work.validation_errors.present?

    # create or delete entry in ORCID record
    if claim_action == "create"
      work.create_work
    elsif claim_action == "delete"
      work.delete_work.merge("data" => work.data, "put_code" => nil)
    end
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
  end

  def work
    Work.new(doi: doi, orcid: uid, access_token: access_token, put_code: put_code)
  end

  def deposit
    { "deposit" => { "subj_id" => orcid_as_url(orcid),
                     "obj_id" => doi_as_url(doi),
                     "source_id" => "datacite_search_link",
                     "publisher_id" => work.publisher_id,
                     "registration_agency_id" => "datacite",
                     "message_type" => "contribution",
                     "message_action" => claim_action,
                     "prefix" => doi[/^10\.\d{4,5}/],
                     "source_token" => ENV['ORCID_UPDATE_UUID'] } }
  end

  def without_control(s)
    r = ''
    s.each_codepoint do |c|
      if c >= 32
        r << c
      end
    end
    r
  end
end
