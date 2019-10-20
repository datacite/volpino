module Countable
  extend ActiveSupport::Concern

  included do
    def get_meta(user_id: nil, state: nil)
      if user_id
        url = ENV['API_URL'] + "/dois?user-id=#{user_id}&page[size]=0"
      else
        url = ENV['API_URL'] + "/dois?page[size]=0"
      end

      response = Maremma.get(url, accept: 'application/vnd.api+json')
      return {} if response.status != 200
      response.body.fetch("meta", {}).slice("created", "resourceTypes")
    end
  end
end
