class User < ActiveRecord::Base
  devise :omniauthable, :omniauth_providers => [:orcid, :github]

  scope :query, ->(query) { where("name like ? OR email like ? OR authentication_token like ?", "%#{query}%", "%#{query}%", "%#{query}%") }

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

  def self.generate_user(auth)
    if User.count > 0 || Rails.env.test?
      authentication_token = generate_authentication_token
      role = "user"
    else
      # use admin role and specific token for first user
      authentication_token = ENV['API_KEY']
      role = "admin"
    end

    { email: auth.info.email,
      name: auth.info.name,
      authentication_token: authentication_token,
      role: role }
  end

  private

  def self.generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
