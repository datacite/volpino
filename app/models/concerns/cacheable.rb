module Cacheable
  extend ActiveSupport::Concern

  module ClassMethods
    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all[:data]
      end
    end

    def cached_provider_response(id, options={})
      Rails.cache.fetch("provider_response/#{id}", expires_in: 1.day) do
        Provider.where(id: id)[:data]
      end
    end

    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
        Client.where(id: id)[:data]
      end
    end
  end
end
