require 'jwt'
require 'orcid_client'

class User < ActiveRecord::Base
  # include helper module for date and time calculations
  include Dateable

  # include helper module for DOI resolution
  include Resolvable

  nilify_blanks

  # include hash helper
  include Hashie::Extensions::DeepFetch

  # include orcid_client
  include OrcidClient::Api

  before_create :set_role

  after_commit :queue_user_job, :on => :create
  after_commit :queue_claim_jobs, :on => :create

  has_many :claims, primary_key: "uid", foreign_key: "orcid", inverse_of: :user
  belongs_to :member

  devise :omniauthable, :omniauth_providers => [:orcid, :github, :google_oauth2, :facebook]

  validates :uid, presence: true, uniqueness: true
  validates :provider, presence: true
  validate :validate_email

  scope :query, ->(query) { where("name like ? OR uid like ? OR github like ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :ordered, -> { order("created_at DESC") }
  scope :order_by_name, -> { order("ISNULL(family_name), family_name") }
  scope :is_public, -> { where("is_public = 1") }
  scope :with_github, -> { where("github IS NOT NULL AND github_put_code IS NULL") }

  serialize :other_names, JSON

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create
  end

  def per_page
    15
  end

  def queue_user_job
    UserJob.perform_later(self)
  end

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end

  def has_email?
    email.present? && errors.empty?
  end

  def orcid
    uid
  end

  def orcid_as_url
    if ENV['ORCID_SANDBOX'].present?
      "http://sandbox.orcid.org/#{orcid}"
    else
      "http://orcid.org/#{orcid}"
    end
  end

  def external_identifier
    ExternalIdentifier.new(type: "GitHub", value: github, url: github_as_url(github), orcid: orcid, access_token: authentication_token, put_code: github_put_code)
  end

  def access_token
    authentication_token
  end

  def credit_name
    name
  end

  def validate_email
    return true if email.blank?

    unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      errors.add :email, "is not a valid email address"
    end
  end

  def self.get_auth_hash(auth, options={})
    { name: auth.info && auth.info.name,
      family_name: auth.info.fetch(:last_name, nil),
      given_names: auth.info.fetch(:first_name, nil),
      other_names: auth.extra.fetch(:raw_info, {}).fetch(:other_names, nil),
      authentication_token: auth.credentials.token,
      expires_at: timestamp(auth.credentials),
      role: auth.extra.fetch(:raw_info, {}).fetch(:role, nil),
      api_key: generate_api_key,
      google_uid: options.fetch("google_uid", nil),
      google_token: options.fetch("google_token", nil),
      email: options.fetch("email", nil),
      facebook_uid: options.fetch("facebook_uid", nil),
      facebook_token: options.fetch("facebook_token", nil),
      github: options.fetch("github", nil),
      github_uid: options.fetch("github_uid", nil),
      github_token: options.fetch("github_token", nil) }.compact
  end

  def self.timestamp(credentials)
    ts = credentials && credentials.expires_at
    ts = Time.at(ts).utc if ts.present?
  end

  def jwt_payload
    claims = {
      uid: uid,
      name: name,
      email: email,
      role: role,
      api_key: api_key,
      iat: Time.now.to_i,
      exp: Time.now.to_i + 14 * 24 * 3600
    }

    JWT.encode(claims, ENV['JWT_SECRET_KEY'])
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

  def collect_data(options={})
    result = get_data(options)
    result = parse_data(result, options)
  end

  def queue_claim_jobs
    claims.notified.find_each { |claim| claim.queue_claim_job }
  end

  def get_data(options={})
    options[:sandbox] = true if ENV['ORCID_SANDBOX'].present?

    response = get_works(options)
    return nil if response.body["errors"]

    works = response.body.fetch("data", {}).fetch("group", {})

    # make sure works with lengh 1 is an array
    works = [works] if works.is_a?(Hash)

    works.select do |work|
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
                                state: 3,
                                put_code: put_code,
                                claimed_at: claimed_at)
        claim.save!
      end

      claim.present? ? claim.doi : nil
    end
  end

  def github_to_be_created?
    github_uid.present? && github_put_code.blank?
  end

  def github_to_be_deleted?
    github_put_code.present?
  end

  def process_data(options={})
    result = push_github_identifier(options)
    logger.info result.inspect

    if result.body["skip"]
    elsif result.body["errors"]
      # send notification to Bugsnag
      if ENV['BUGSNAG_KEY']
        Bugsnag.notify(RuntimeError.new(result.body["errors"].first["title"]))
      end
    else
      write_attribute(:github_put_code, result.body["put_code"])
    end

    logger.info "Added Github username to ORCID record for user #{orcid}."
  end

  def push_github_identifier(options={})
    # user has not linked github username
    return OpenStruct.new(body: { "skip" => true }) unless github_to_be_created? || github_to_be_deleted?

    options[:sandbox] = true if ENV['ORCID_SANDBOX'].present?

    # missing data raise errors
    return OpenStruct.new(body: { "errors" => [{ "title" => "Missing data" }] }) if external_identifier.data.nil?

    # validate data
    return OpenStruct.new(body: { "errors" => external_identifier.validation_errors.map { |error| { "title" => error } }}) if external_identifier.validation_errors.present?

    # create or delete entry in ORCID record
    if github_to_be_created?
      external_identifier.create_external_identifier(options)
    elsif github_to_be_deleted?
      external_identifier.delete_external_identifier(options)
    end
  end

  def set_role
    # use admin role for first user
    write_attribute(:role, "admin") if User.count == 0 && role.blank?
  end

  private

  def self.generate_api_key
    loop do
      token = Devise.friendly_token
      break token unless User.where(api_key: token).first
    end
  end
end
