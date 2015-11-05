require 'jwt'

class User < ActiveRecord::Base
  devise :omniauthable, :omniauth_providers => [:orcid, :github, :persona]

  has_many :applications, class_name: 'Doorkeeper::Application', as: :owner

  scope :query, ->(query) { where("name like ? OR uid like ? OR authentication_token like ?", "%#{query}%", "%#{query}%", "%#{query}%") }
  scope :ordered, -> { order("created_at DESC") }

  serialize :other_names, JSON

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create(generate_user(auth))
  end

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  def api_key
    authentication_token
  end

  def orcid
    if provider == 'orcid'
      "http://orcid.org/#{uid}"
    end
  end

  def self.generate_user(auth)
    if User.count > 0 || Rails.env.test?
      role = "user"
    else
      role = "admin"
    end

    timestamp = auth.credentials && auth.credentials.expires_at
    timestamp = Time.at(timestamp).utc if timestamp.present?

    { name: auth.info && auth.info.name,
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

  private

  def self.generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
