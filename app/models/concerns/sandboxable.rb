module Sandboxable
  extend ActiveSupport::Concern

  require 'base32/crockford'

  included do
    def write_sandbox(value)
      #return true if Client.where("name" => value)[:data]

      # url = "#{ENV["LUPO_URL"]}/clients"
      # Maremma.post(query_url, options)
      # sandbox.name if sandbox.present?

    end
  end
end
