module Countable
  extend ActiveSupport::Concern

  included do
    def doi_count(user_id: nil, state: nil)
      if user_id
        url = ENV['API_URL'] + "/dois?user-id=#{user_id}&page[size]=0"
      else
        url = ENV['API_URL'] + "/dois?page[size]=0"
      end

      response = Maremma.get(url, accept: 'application/vnd.api+json')
      return [] if response.status != 200

      response.body.dig("meta", "created") || []
    end

    def resource_type_count(user_id: nil, state: nil)
      if user_id
        url = ENV['API_URL'] + "/dois?user-id=#{user_id}&page[size]=0"
      else
        url = ENV['API_URL'] + "/dois?page[size]=0"
      end

      response = Maremma.get(url, accept: 'application/vnd.api+json')
      return [] if response.status != 200

      response.body.dig("meta", "resourceTypes") || []
    end
  end
end
