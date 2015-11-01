require 'jwt'

class User < ActiveRecord::Base
  devise :omniauthable, :omniauth_providers => [:orcid, :github, :persona]

  has_many :applications, class_name: 'Doorkeeper::Application', as: :owner

  scope :query, ->(query) { where("name like ? OR email like ? OR uid = ?", "%#{query}%", "%#{query}%", "%#{query}%") }

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
      "https://orcid.org/#{uid}"
    end
  end

  def self.generate_user(auth)
    authentication_token = generate_authentication_token

    if User.count > 0 || Rails.env.test?
      role = "user"
    else
      role = "admin"
    end

    { email: auth.info.email,
      name: auth.info.name,
      authentication_token: authentication_token,
      role: role }
  end

  def jwt_payload
    claims = {
      uid: uid,
      name: name,
      email: email,
      api_key: api_key,
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
