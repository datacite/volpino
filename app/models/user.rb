require 'jwt'

class User < ActiveRecord::Base
  # include helper module for orcid oauth
  include Clientable

  # include helper module for date and time calculations
  include Dateable

  after_commit :queue_user_job, :on => :create

  has_many :claims, primary_key: "uid", foreign_key: "uid"

  devise :confirmable, :omniauthable, :omniauth_providers => [:orcid]

  validates :uid, presence: true, uniqueness: true
  validates :provider, presence: true
  validate :validate_email

  scope :query, ->(query) { where("name like ? OR uid like ?", "%#{query}%", "%#{query}%") }
  scope :ordered, -> { order("created_at DESC") }

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

  def has_unconfirmed_email?
    unconfirmed_email.present? && errors.empty?
  end

  def orcid
    "http://orcid.org/#{uid}"
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

  def self.get_auth_hash(auth)
    if Rails.env.test?
      role = "admin"
    elsif User.count > 1
      role = "user"
    else
      role = "admin"
    end

    timestamp = auth.credentials && auth.credentials.expires_at
    timestamp = Time.at(timestamp).utc if timestamp.present?

    { name: auth.info && auth.info.name,
      family_name: auth.info.fetch(:last_name, nil),
      given_names: auth.info.fetch(:first_name, nil),
      other_names: auth.extra.fetch(:raw_info, {}).fetch(:other_names, nil),
      authentication_token: auth.credentials.token,
      expires_at: timestamp,
      role: role,
      api_key: generate_authentication_token }
  end

  def jwt_payload
    claims = {
      uid: uid,
      authentication_token: authentication_token,
      expires_at: expires_at,
      name: name,
      email: email,
      role: role,
      iat: Time.now.to_i
    }

    JWT.encode(claims, ENV['JWT_SECRET_KEY'])
  end

  def reversed_name
    [family_name.to_s, given_names].join(', ')
  end

  def names_for_search
    ([uid, name, reversed_name].compact + Array(other_names).compact).map { |n| '"' + n + '"' }.join(" OR ")
  end

  def orcid_url
    "http://pub.orcid.org/v#{ORCID_VERSION}/#{uid}/orcid-works"
  end

  def process_data(options={})
    result = get_data(options)
    result = parse_data(result, options)
  end

  def get_data(options={})
    result = Maremma.get(orcid_url)
    return result if result["errrors"]

    result.fetch("data", {})
          .fetch("orcid-profile", {})
          .fetch("orcid-activities", {})
          .fetch("orcid-works", {})
          .fetch("orcid-work", [])
          .select { |item| item.fetch("source", {}).fetch("source-orcid", {}).fetch("path", nil) == ENV['ORCID_CLIENT_ID'] }
  end

  def parse_data(items, options={})
    Array(items).map do |item|
      doi = item.fetch("work-external-identifiers", {})
                .fetch("work-external-identifier", [])
                .find { |item| item.fetch("work-external-identifier-type", nil) == "DOI" }
                .fetch("work-external-identifier-id", {}).fetch("value", nil)
      claimed_at = get_iso8601_from_epoch(item.fetch("source", {}).fetch("source-date", {}).fetch("value", nil))

      claim = Claim.where(uid: uid, doi: doi).first_or_create!(
                          source_id: "orcid_search",
                          state: 3,
                          claimed_at: claimed_at)
      claim.present? ? claim.doi : nil
    end
  end

  protected

  def confirmation_required?
    false
  end

  private

  def self.generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
