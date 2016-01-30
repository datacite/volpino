class Deposit < ActiveRecord::Base
  before_create :create_uuid
  after_commit :queue_deposit_job, :on => :create

  state_machine :initial => :waiting do
    state :waiting, value: 0
    state :working, value: 1
    state :failed, value: 2
    state :done, value: 3

    after_transition :to => :done do |deposit|
      if deposit.callback.present?
        data = { "deposit" => {
                   "id" => deposit.uuid,
                   "state" => "done",
                   "message_type" => deposit.message_type,
                   "message_action" => deposit.message_action,
                   "message_size" => deposit.message_size,
                   "source_token" => deposit.source_token,
                   "timestamp" => Time.zone.now.iso8601
                 }
               }
        Maremma.post(deposit.callback, data: data.to_json, token: ENV['API_KEY'])
      end
    end

    after_transition :to => :failed do |deposit|
      if deposit.callback.present?
        data = { "deposit" => {
                   "id" => deposit.uuid,
                   "state" => "failed",
                   "message_type" => deposit.message_type,
                   "message_action" => deposit.message_action,
                   "message_size" => 0,
                   "source_token" => deposit.source_token,
                   "timestamp" => Time.zone.now.iso8601
                 }
               }
        Maremma.post(deposit.callback, data: data.to_json, token: ENV['API_KEY'])
      end
    end

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
  end

  serialize :message, JSON

  validates :source_token, presence: true
  validates :message, presence: true
  validate :validate_message

  scope :by_state, ->(state) { where("state = ?", state) }
  scope :order_by_date, -> { order("updated_at DESC") }

  scope :waiting, -> { by_state(0).order_by_date }
  scope :working, -> { by_state(1).order_by_date }
  scope :failed, -> { by_state(2).order_by_date }
  scope :done, -> { by_state(3).order_by_date }
  scope :total, ->(duration) { where(updated_at: (Time.zone.now.beginning_of_hour - duration.hours)..Time.zone.now.beginning_of_hour) }

  def self.per_page
    1000
  end

  def queue_deposit_job
    DepositJob.perform_later(self)
  end

  def to_param  # overridden, use uuid instead of id
    uuid
  end

  def validate_message
    if message.is_a?(Hash)
      message['contributors'] ||
      errors.add(:message, "should contain contributors")
    else
      errors.add(:message, "should be a hash")
    end
  end

  def indifferent_message
    message.with_indifferent_access
  end

  def update_contributions
    indifferent_message.fetch(:contributors, []).map do |item|
      uid = item.fetch('uid', "")[17..-1]
      doi = item.fetch('related_works', {}).fetch('pid', "")[15..-1]
      source_id = item.fetch('related_works', {}).fetch('source_id', nil)

      next unless uid.present? && doi.present? && source_id.present?

      Claim.create!(uid: uid,
                    doi: doi,
                    source_id: source_id)
    end
  end

  def delete_contributions
    indifferent_message.fetch("contributors", []).map do |item|
      uid = item.fetch('uid', "")[17..-1]
      doi = item.fetch('related_works', {}).fetch('pid', "")[15..-1]
      source_id = item.fetch('related_works', {}).fetch('source_id', nil)

      next unless uid.present? && doi.present? && source_id.present?

      Claim.destroy_all(uid: uid,
                        doi: doi,
                        source_id: source_id)
    end
  end

  def message_size
    @message_size || indifferent_message.fetch(:contributors, []).size
  end

  def timestamp
    updated_at.utc.iso8601
  end

  def cache_key
    "deposit/#{uuid}-#{timestamp}"
  end

  def create_uuid
    write_attribute(:uuid, SecureRandom.uuid) if uuid.blank?
    write_attribute(:message_type, 'default') if message_type.blank?
  end
end
