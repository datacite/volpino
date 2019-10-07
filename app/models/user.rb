require 'orcid_client'

class User < ActiveRecord::Base
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

  # include hash helper
  include Hashie::Extensions::DeepFetch

  # include orcid_client
  include OrcidClient::Api

  attr_reader :role

  before_create :set_role

  after_commit :queue_user_job, :on => :create
  after_commit :queue_claim_jobs, :on => :create

  has_many :claims, primary_key: "uid", foreign_key: "orcid", inverse_of: :user

  devise :omniauthable, :omniauth_providers => [:orcid, :github, :globus]

  validates :uid, presence: true, uniqueness: true
  validate :validate_email

  scope :q, ->(query) { where("name like ? OR uid like ? OR email like ? OR github like ?", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :ordered, -> { order("created_at DESC") }
  scope :order_by_name, -> { order("ISNULL(family_name), family_name") }
  scope :is_public, -> { where("is_public = 1") }
  scope :with_github, -> { where("github IS NOT NULL AND github_put_code IS NULL") }

  alias_attribute :created, :created_at
  alias_attribute :updated, :updated_at

  serialize :other_names, JSON

  # use different index for testing
  index_name Rails.env.test? ? "users-test" : "users"

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
      indexes :uid,           type: :keyword
      indexes :name,          type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :given_names,   type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :family_name,   type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }}
      indexes :github,        type: :keyword
      indexes :role_id,       type: :keyword
      indexes :created,       type: :date
      indexes :updated,       type: :date
      indexes :is_active,     type: :boolean
    end
  end

  # also index id as workaround for finding the correct key in associations
  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "name" => name,
      "given_names" => given_names,
      "family_name" => family_name,
      "github" => github,
      "created" => created,
      "updated" => updated,
      "role_id" => role_id,
      "is_active" => is_active
    }
  end

  def self.query_fields
    ['uid^10', 'name^5', 'given_names^5', 'family_name^5', '_all']
  end

  def self.from_omniauth(auth, options={})
    where(provider: options[:provider], uid: options[:uid] || auth.uid).first_or_create
  end

  def queue_user_job
    UserJob.perform_later(self)
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
    Rails.env.test? ? ENV['ORCID_URL'] + "/" + orcid : "https://orcid.org/" + orcid
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

    unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      errors.add :email, "is not a valid email address"
    end
  end

  def self.get_auth_hash(auth, options={})
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
    ts = credentials && credentials.expires_at
    ts = Time.at(ts).utc if ts.present?
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
      exp: Time.now.to_i + 30 * 24 * 3600
    }.compact

    encode_token(payload)
  end

  def reversed_name
    [family_name.to_s, given_names].join(', ')
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

  def collect_data(options={})
    result = get_data(options)
    result = parse_data(result, options)
  end

  def queue_claim_jobs
    claims.notified.find_each { |claim| claim.queue_claim_job }
  end

  def get_data(options={})
    options[:sandbox] = (ENV['ORCID_URL'] == "https://sandbox.orcid.org")

    response = get_works(options)
    return nil if response.body["errors"]

    works = response.body.fetch("data", {}).fetch("group", {})

    Array.wrap(works).select do |work|
      work.extend Hashie::Extensions::DeepFetch
      work.deep_fetch('work-summary', 0, 'source', 'source-client-id', 'path') { nil } == ENV['ORCID_CLIENT_ID']
    end
  end

  def parse_data(works, options={})
    Array(works).map do |work|
      work.extend Hashie::Extensions::DeepFetch
      doi = work.deep_fetch('external-ids', 'external-id', 0, 'external-id-value') { nil }
      claimed_at = get_iso8601_from_epoch(work.deep_fetch('last-modified-date', 'value') { nil })
      put_code = work.deep_fetch('work-summary', 0, 'put-code') { nil }

      claim = Claim.where(orcid: orcid, doi: doi).first_or_initialize
      if claim.put_code.blank?
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

  def process_data(options={})
    logger = Logger.new(STDOUT)

    result = push_github_identifier(options)
    logger.info result.inspect

    if result.body["skip"]
    elsif result.body["errors"]
      # send notification to Sentry
      if ENV["SENTRY_DSN"]
        Raven.capture_exception(RuntimeError.new(result.body["errors"].first["title"]))
      else
        logger.error result.body["errors"].first["title"]
      end
    else
      write_attribute(:github_put_code, result.body["put_code"])
    end

    logger.info "Added Github username to ORCID record for user #{orcid}."
  end

  def push_github_identifier(options={})
    # user has not linked github username
    return OpenStruct.new(body: { "skip" => true }) unless github_to_be_created? || github_to_be_deleted?

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if external_identifier.data.nil?

    # validate data
    return OpenStruct.new(body: { "errors" => external_identifier.validation_errors.map { |error| { "title" => error } }}) if external_identifier.validation_errors.present?

    options[:sandbox] = (ENV['ORCID_URL'] == "https://sandbox.orcid.org")

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
