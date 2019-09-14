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

  SUBJECT = "Add your published work(s) to your ORCID record"
  INTRO =  "Hello, You may not be familiar with DataCite. Our data centers send us publication information (including ORCID iDs and DOIs), and we ensure that your work can be found, linked and cited. It looks like you have included your ORCID iD with a recent publication submission and that has been passed to us by your data center. We would like to auto-update your ORCID record with information about these published work(s) published, starting today with those listed below, so you don’t have to search for and add them manually, now or in the future. Please click ‘Grant permissions’ below to set this up."

  belongs_to :user, foreign_key: "orcid", primary_key: "uid", inverse_of: :claims

  before_create :create_uuid
  after_commit :queue_claim_job, on: [:create, :update], if: Proc.new { |claim| claim.waiting? }

  validates :orcid, :doi, :source_id, presence: true

  delegate :uid, to: :user, allow_nil: true
  delegate :orcid_token, to: :user, allow_nil: true

  alias_attribute :state, :aasm_state

  aasm :whiny_transitions => false do
    # waiting is initial state for new claims
    state :waiting, :initial => true
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
      transitions from: [:waiting, :working, :deleted, :notified], to: :ignored
    end
  end

  scope :by_state, ->(state) { where(aasm_state: state) }
  scope :order_by_date, -> { order("updated_at DESC") }

  scope :waiting, -> { by_state("waiting").order_by_date }
  scope :working, -> { by_state("working").order_by_date }
  scope :failed, -> { by_state("failes").order_by_date }
  scope :done, -> { by_state("done").order_by_date }
  scope :ignored, -> { by_state("ignored").order_by_date }
  scope :deleted, -> { by_state("deleted").order_by_date }
  scope :notified, -> { by_state("notified").order_by_date }
  scope :stale, -> { where(aasm_state: ["waiting", "working"]).order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  scope :query, ->(query) { where("doi like ?", "%#{query}%") }
  scope :search_and_link, -> { where(source_id: "orcid_search").where("claimed_at IS NOT NULL") }
  scope :auto_update, -> { where(source_id: "orcid_update").where("claimed_at IS NOT NULL") }
  scope :total_count, -> { where(claim_action: "create").count }

  serialize :error_messages, JSON

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

  def process_data(options={})
    self.start
    result = collect_data

    if result.body["skip"]
      claimed_at.present? ? self.finish : self.skip
    elsif result.body["errors"]
      write_attribute(:error_messages, result.body["errors"])

      # send notification to Bugsnag
      if ENV['BUGSNAG_KEY']
        Bugsnag.notify(RuntimeError.new(result.body["errors"].first["title"]))
      end

      self.error
    elsif result.body["notification"]
      write_attribute(:put_code, result.body["put_code"])
      write_attribute(:error_messages, nil)
      self.notify
    else
      if to_be_created?
        write_attribute(:claimed_at, Time.zone.now)
        write_attribute(:put_code, result.body["put_code"])
        write_attribute(:error_messages, nil)
      elsif to_be_deleted?
        write_attribute(:claimed_at, nil)
        write_attribute(:put_code, nil)
        write_attribute(:error_messages, nil)
      end

      self.finish
    end
  end

  def collect_data(options={})
    # already claimed
    return OpenStruct.new(body: { "skip" => true }) if to_be_created? && claimed_at.present?

    # user has not signed up yet or orcid_token is missing
    return OpenStruct.new(body: { "skip" => true }) unless user.present? && user.orcid_token.present?

    # user has not given permission for auto-update
    return OpenStruct.new(body: { "skip" => true }) if source_id == "orcid_update" && user && !user.auto_update

    options[:sandbox] = Rails.env.test?

    # user has not signed up yet or orcid_token is missing
    unless (user.present? && user.orcid_token.present?)
      if ENV['NOTIFICATION_ACCESS_TOKEN'].present?
        response = notification.create_notification(options)
        response.body["notification"] = true
        return response
      else
        return OpenStruct.new(body: { "skip" => true })
      end
    end

    # user has too many claims already
    return OpenStruct.new(body: { "errors" => [{ "title" => "Too many claims. Only 10,000 claims allowed." }] }) if user.claims.total_count > 10000

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if work.data.nil?

    # validate data
    return OpenStruct.new(body: { "errors" => work.validation_errors.map { |error| { "title" => error } }}) if work.validation_errors.present?

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
    Work.new(doi: doi, orcid: orcid, access_token: orcid_token, put_code: put_code)
  end

  def notification
    Notification.new(doi: doi, orcid: orcid, notification_access_token: ENV['NOTIFICATION_ACCESS_TOKEN'], put_code: put_code, subject: SUBJECT, intro: INTRO)
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
