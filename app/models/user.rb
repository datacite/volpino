require 'jwt'

class User < ActiveRecord::Base
  # include helper module for orcid oauth
  include Clientable

  has_many :claims

  devise :omniauthable, :omniauth_providers => [:orcid]

  validates :uid, presence: true, uniqueness: true
  validates :provider, presence: true

  scope :query, ->(query) { where("name like ? OR uid like ?", "%#{query}%", "%#{query}%") }
  scope :ordered, -> { order("created_at DESC") }

  serialize :other_names, JSON

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create
  end

  def per_page
    15
  end

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end

  def orcid
    "http://orcid.org/#{uid}"
  end

  def credit_name
    name
  end

  def self.get_auth_hash(auth)
    if User.count > 1 || Rails.env.test?
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
    ([uid, name, reversed_name].compact + Array(other_names)).map { |n| '"' + n + '"' }.join(" OR ")
  end

  private

  def self.generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
