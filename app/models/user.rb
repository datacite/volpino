# frozen_string_literal: true

require "orcid_client"

class User < ApplicationRecord
  # include helper module for date and time calculations
  include Dateable

  # include helper module for DOI resolution
  include Resolvable

  # include helper module for JWT encode and decode
  include Authenticable

  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for Elasticsearch
  include Indexable

  include Elasticsearch::Model

  nilify_blanks
  strip_attributes only: %i[given_names family_name name other_names]

  # include hash helper
  include Hashie::Extensions::DeepFetch

  # include orcid_client
  include OrcidClient::Api

  attr_reader :role

  before_create :set_role

  after_commit :queue_user_job, on: :create
  after_commit :queue_claim_jobs, on: :create

  has_many :claims, primary_key: "uid", foreign_key: "orcid", inverse_of: :user

  devise :omniauthable, omniauth_providers: %i[orcid github globus]

  validates :uid, presence: true, uniqueness: { case_sensitive: false }
  validate :validate_email

  scope :q, ->(query) { where("name like ? OR uid like ? OR email like ? OR github like ?", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :is_public, -> { where("is_public = 1") }
  scope :with_github, -> { where("github IS NOT NULL AND github_put_code IS NULL") }

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at
  alias_attribute :given_name, :given_names

  serialize :other_names, JSON

  # use different index for testing
  index_name Rails.env.test? ? "users-test" : "users"

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: "keyword", filter: %w(lowercase ascii_folding) },
      },
      filter: { ascii_folding: { type: "asciifolding", preserve_original: true } },
    },
  } do
    mapping dynamic: "false" do
      indexes :id,            type: :keyword
      indexes :uid,           type: :keyword
      indexes :name,          type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } }
      indexes :given_name,    type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } }
      indexes :family_name,   type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } }
      indexes :email,         type: :keyword
      indexes :github,        type: :keyword
      indexes :role_id,       type: :keyword
      indexes :role_name,     type: :keyword
      indexes :orcid_token,   type: :keyword
      indexes :created,       type: :date
      indexes :updated,       type: :date
      indexes :orcid_expires_at, type: :date
      indexes :is_active,     type: :boolean
      indexes :beta_tester,   type: :boolean
      indexes :is_public,     type: :boolean
      indexes :auto_update,   type: :boolean
      indexes :claims_count,  type: :integer
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(_options = {})
    {
      "id" => uid,
      "uid" => uid,
      "name" => name,
      "given_name" => given_name,
      "family_name" => family_name,
      "email" => email,
      "github" => github,
      "created" => created,
      "updated" => updated,
      "role_id" => role_id,
      "role_name" => role_name,
      "beta_tester" => beta_tester,
      "is_public" => is_public,
      "auto_update" => auto_update,
      "is_active" => is_active,
      "orcid_token" => orcid_token,
      "orcid_expires_at" => orcid_expires_at,
      "claims_count" => claims_count,
    }
  end

  def self.query_fields
    ["uid^50", "name^5", "given_name^5", "family_name^5", "_all"]
  end

  def self.query_aggregations
    {
      created: { date_histogram: { field: "created", interval: "year", min_doc_count: 1 } },
      roles: { terms: { field: "role_id", size: 15, min_doc_count: 1 } },
    }
  end

  def self.from_omniauth(auth, options = {})
    where(provider: options[:provider], uid: options[:uid] || auth.uid).first_or_create
  end

  def self.import_by_ids(options = {})
    from_id = (options[:from_id] || User.minimum(:id)).to_i
    until_id = (options[:until_id] || User.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      UserImportByIdJob.perform_later(options.merge(id: id))
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index = if Rails.env.test?
      "users-test"
    elsif options[:index].present?
      options[:index]
    else
      inactive_index
    end
    errors = 0
    count = 0

    User.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |users|
      response = User.__elasticsearch__.client.bulk \
        index: index,
        type: User.document_type,
        body: users.map { |user| { index: { _id: user.id, data: user.as_indexed_json } } }

      # try to handle errors
      response["items"].select { |k, _v| k.values.first["error"].present? }.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
        id = item.dig("index", "_id").to_i
        user = User.where(id: id).first
        IndexJob.perform_later(user) if user.present?
      end

      count += users.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} users with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} users with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => e
    Rails.logger.info "[Elasticsearch] Error #{e.message} importing users with IDs #{id} - #{(id + 499)}."

    count = 0

    User.where(id: id..(id + 499)).find_each do |user|
      IndexJob.perform_later(user)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} users with IDs #{id} - #{(id + 499)}."

    count
  end

  def queue_user_job
    UserJob.perform_later(self)
  end

  def self.delete_expired_token(index: nil)
    query = "orcid_expires_at:[1970-01-02 TO #{Date.today.strftime('%F')}]"

    response = User.query(query, index: index, page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} Users with expired ORCID token found."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while !response.results.results.empty?
        response = User.query(query, index: index, page: { size: 1000, cursor: cursor })
        break if response.results.results.empty?

        Rails.logger.info "Deleting #{response.results.to_a.length} User ORCID tokens starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.records.each do |user|
          UserTokenJob.perform_later(user)
        end
      end
    end

    response.results.total
  end

  def claims_count
    claims.size
  end

  # Helper method to check for admin user
  def is_admin?
    role_id == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["staff_admin", "staff_user"].include?(role_id)
  end

  # Helper method to check for beta tester
  def is_beta_tester?
    beta_tester
  end

  def has_email?
    email.present? && errors.empty?
  end

  def orcid
    uid
  end

  def orcid_as_url
    Rails.env.test? ? ENV["ORCID_URL"] + "/" + orcid : "https://orcid.org/" + orcid
  end

  def flipper_id
    uid
  end

  def features
    { "delete-doi" => Flipper[:delete_doi].enabled?(self) }
  end

  def external_identifier
    ExternalIdentifier.new(type: "GitHub", value: github, url: github_as_url(github), orcid: orcid, orcid_token: orcid_token, put_code: github_put_code)
  end

  def access_token
    authentication_token
  end

  def is_active
    authentication_token.present?
  end

  def credit_name
    name
  end

  def role
    cached_role_response(role_id) if role_id.present?
  end

  def role_name
    role.name if role_id.present?
  end

  def validate_email
    return true if email.blank?

    unless /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match?(email)
      errors.add :email, "is not a valid email address"
    end
  end

  def self.get_auth_hash(auth, options = {})
    { name: auth.info && auth.info.name.to_s.strip,
      family_name: auth.info.fetch(:last_name, "").to_s.strip,
      given_names: auth.info.fetch(:first_name, "").to_s.strip,
      other_names: auth.extra.fetch(:raw_info, {}).fetch(:other_names, nil),
      organization: auth.extra.id_info? ? auth.extra.id_info.organization : nil,
      authentication_token: options.fetch(:authentication_token, nil),
      expires_at: options.fetch(:expires_at, "1970-01-01"),
      role_id: auth.extra.fetch(:raw_info, {}).fetch(:role_id, nil),
      github: options.fetch("github", nil),
      github_uid: options.fetch("github_uid", nil),
      github_token: options.fetch("github_token", nil),
      email: auth.extra.id_info? ? auth.extra.id_info.email : nil }.compact
  end

  def self.timestamp(credentials)
    ts = credentials&.expires_at
    Time.at(ts).utc if ts.present?
  end

  def jwt
    payload = {
      uid: uid,
      name: name,
      email: email,
      role_id: role_id,
      beta_tester: beta_tester,
      has_orcid_token: has_orcid_token,
      features: features,
      iat: Time.now.to_i,
      exp: Time.now.to_i + 30 * 24 * 3600,
    }.compact

    encode_token(payload)
  end

  def reversed_name
    [family_name.to_s, given_names].join(", ")
  end

  def display_name
    name.presence || uid
  end

  def names_for_search
    ([uid, name, reversed_name].compact + Array(other_names).compact).map { |n| '"' + n + '"' }.join(" OR ")
  end

  def has_orcid_token
    orcid_token.present?
  end

  def collect_data(options = {})
    result = get_data(options)
    parse_data(result, options)
  end

  def queue_claim_jobs
    # claims.notified.find_each { |claim| claim.queue_claim_job }
    claims.failed.find_each(&:queue_claim_job)
  end

  def get_data(options = {})
    options[:sandbox] = (ENV["ORCID_URL"] == "https://sandbox.orcid.org")

    response = get_works(options)
    return nil if response.body["errors"]

    works = response.body.fetch("data", {}).fetch("group", {})

    Array.wrap(works).select do |work|
      work.extend Hashie::Extensions::DeepFetch
      work.deep_fetch("work-summary", 0, "source", "source-client-id", "path") { nil } == ENV["ORCID_CLIENT_ID"]
    end
  end

  def parse_data(works, _options = {})
    Array(works).map do |work|
      work.extend Hashie::Extensions::DeepFetch
      doi = work.deep_fetch("external-ids", "external-id", 0, "external-id-value") { nil }
      claimed_at = get_iso8601_from_epoch(work.deep_fetch("last-modified-date", "value") { nil })
      put_code = work.deep_fetch("work-summary", 0, "put-code") { nil }

      claim = Claim.where(orcid: orcid, doi: doi).first_or_initialize
      if claim.put_code.blank?
        logger.info "[User] #{orcid} – #{doi}: Updating claim details for user"
        source_id = claim.new_record? ? "orcid_search" : claim.source_id
        claim.assign_attributes(source_id: source_id,
                                state: "done",
                                put_code: put_code,
                                claimed_at: claimed_at)
        claim.save!
      end

      claim.present? ? claim.doi : nil
    end
  end

  def github_to_be_created?
    github.present? && github_put_code.blank?
  end

  def github_to_be_deleted?
    github.present? && github_put_code.present?
  end

  def process_data(options = {})
    result = push_github_identifier(options)

    if result.body["skip"]
    elsif result.body["errors"]
      # send notification to Sentry
      # Raven.capture_exception(RuntimeError.new(result.body["errors"].first["title"]))if ENV["SENTRY_DSN"]

      logger.error result.body["errors"].inspect
    else
      write_attribute(:github_put_code, result.body["put_code"])
    end

    logger.info "Added Github username to ORCID record for user #{orcid}."
  end

  def push_github_identifier(options = {})
    # user has not linked github username
    return OpenStruct.new(body: { "skip" => true }) unless github_to_be_created? || github_to_be_deleted?

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if external_identifier.data.nil?

    # validate data
    return OpenStruct.new(body: { "errors" => external_identifier.validation_errors.map { |error| { "title" => error } } }) if external_identifier.validation_errors.present?

    options[:sandbox] = (ENV["ORCID_URL"] == "https://sandbox.orcid.org")

    # create or delete entry in ORCID record
    if github_to_be_created?
      external_identifier.create_external_identifier(options)
    elsif github_to_be_deleted?
      external_identifier.delete_external_identifier(options)
    end
  end

  def set_role
    # use admin role for first user
    write_attribute(:role_id, "staff_admin") if User.count == 0 && role_id.blank?
  end
end
