module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_provider_response(id, options={})
      Rails.cache.fetch("provider_response/#{id}", expires_in: 1.day) do
        provider = Provider.where(id: id)
        provider[:data] if provider.present?
      end
    end

    def cached_client_response(id, options={})
      Rails.cache.fetch("client_response/#{id}", expires_in: 1.day) do
        client = Client.where(id: id)
        client[:data] if client.present?
      end
    end

    def cached_role_response(id, options={})
      Rails.cache.fetch("role_response/#{id}", expires_in: 7.days) do
        role = Role.where(id: id)
        role[:data] if role.present?
      end
    end
  end

  module ClassMethods
    def cached_providers
      Rails.cache.fetch("providers", expires_in: 1.day) do
        Provider.all[:data]
      end
    end
  end
end
