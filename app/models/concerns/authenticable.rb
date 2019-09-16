module Authenticable
  extend ActiveSupport::Concern

  require 'jwt'

  included do
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, 'RS256')
    end

    # decode token using SHA-256 hash algorithm
    def decode_token(token)
      public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
      payload = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first

      # check whether token has expired
      return {} unless Time.now.to_i < payload["exp"]

      payload
    rescue JWT::DecodeError => error
      Rails.logger.error "JWT::DecodeError: " + error.message + " for " + token
      return {}
    rescue OpenSSL::PKey::RSAError => error
      public_key = ENV['JWT_PUBLIC_KEY'].presence || "nil"
      Rails.logger.error "OpenSSL::PKey::RSAError: " + error.message + " for " + public_key
      return {}
    end

    def encode_cookie(jwt)
      expires_in = 30 * 24 * 3600
      expires_at = Time.now.to_i + expires_in
      value = '{"authenticated":{"authenticator":"authenticator:oauth2","access_token":"' + jwt + '","expires_in":' + expires_in.to_s + ',"expires_at":' + expires_at.to_s + '}}'
      
      domain = if Rails.env.production?
                 ".datacite.org"
               elsif Rails.env.stage?
                 ".test.datacite.org"
               else
                 nil
               end
      
      # URI.encode optional parameter needed to encode colon
      { value: value, #URI.encode(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        secure: !Rails.env.development? && !Rails.env.test?,
        domain: domain }
    end
  end
end
