# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  require "jwt"

  included do
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, "RS256")
    end

    # decode token using SHA-256 hash algorithm
    def decode_token(token)
      public_key = OpenSSL::PKey::RSA.new(ENV["JWT_PUBLIC_KEY"].to_s.gsub('\n', "\n"))
      payload = (JWT.decode token, public_key, true, algorithm: "RS256").first

      # check whether token has expired
      return {} unless Time.now.to_i < payload["exp"].to_i

      payload
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT::DecodeError: " + e.message + " for " + token
      {}
    rescue OpenSSL::PKey::RSAError => e
      public_key = ENV["JWT_PUBLIC_KEY"].presence || "nil"
      Rails.logger.error "OpenSSL::PKey::RSAError: " + e.message + " for " + public_key
      {}
    end

    def encode_cookie(jwt)
      expires_in = 30 * 24 * 3600
      expires_at = Time.now.to_i + expires_in
      value = '{"authenticated":{"authenticator":"authenticator:oauth2","access_token":"' + jwt + '","expires_in":' + expires_in.to_s + ',"expires_at":' + expires_at.to_s + "}}"

      domain = if Rails.env.production?
        ".datacite.org"
      elsif Rails.env.stage? && ENV["ES_PREFIX"].present?
        ".stage.datacite.org"
      elsif Rails.env.stage?
        ".test.datacite.org"
      else
        "localhost"
      end

      # URI.encode optional parameter needed to encode colon
      { value: value, # URI.encode(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        secure: !Rails.env.development? && !Rails.env.test?,
        domain: domain }
    end
  end

  module ClassMethods
    # encode token using SHA-256 hash algorithm
    def encode_token(payload)
      return nil if payload.blank?

      # replace newline characters with actual newlines
      private_key = OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"].to_s.gsub('\n', "\n"))
      JWT.encode(payload, private_key, "RS256")
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.error e.inspect + " for " + payload.inspect

      nil
    end

    # generate JWT token
    def generate_token(attributes = {})
      payload = {
        uid: attributes.fetch(:uid, "0000-0001-5489-3594"),
        name: attributes.fetch(:name, "Josiah Carberry"),
        email: attributes.fetch(:email, nil),
        provider_id: attributes.fetch(:provider_id, nil),
        client_id: attributes.fetch(:client_id, nil),
        role_id: attributes.fetch(:role_id, "staff_admin"),
        password: attributes.fetch(:password, nil),
        iat: Time.now.to_i,
        exp: Time.now.to_i + attributes.fetch(:exp, 30),
      }.compact

      encode_token(payload)
    end
  end
end
