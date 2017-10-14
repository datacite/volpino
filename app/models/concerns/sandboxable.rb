module Sandboxable
  extend ActiveSupport::Concern

  require 'base32/crockford'
  require 'securerandom'

  UPPER_LIMIT = 34359738367

  included do
    def random_suffix
      number = SecureRandom.random_number(UPPER_LIMIT)
      Base32::Crockford.encode(number, split: 4, length: 8, checksum: true).downcase
    end

    def write_sandbox(client_name, jwt: nil)
      url = "#{ENV["LUPO_URL"]}/clients"
      data = { "data" => { "attributes" => {
                             "name" => client_name,
                             "symbol" => sandbox_id.upcase,
                             "domains" => '*',
                             "contact_name" => name,
                             "contact_email" => email,
                             "is_active" => true }.compact,
                           "relationships" => {
                             "provider" => {
                               "data" => {
                                 "type" => "providers",
                                 "id" => "sandbox" }
                             }
                           },
                           "type" => "clients" }
                         }

      result = Maremma.post(url, content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json', bearer: jwt, data: data.to_json)
      Rails.logger.info result.inspect
    end
  end
end
