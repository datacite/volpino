# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_role_response(id, _options = {})
      Rails.cache.fetch("role_response/#{id}", expires_in: 7.days) do
        role = Role.where(id: id)
        role[:data] if role.present?
      end
    end
  end
end
