# frozen_string_literal: true

class QueryType < BaseObject
  field :user, UserType, null: true do
    argument :id, ID, required: true
  end

  def user(id:)
    ElasticsearchLoader.for(User).load(orcid_from_url(id))
  end

  field :users, UserConnectionWithMetaType, null: false, connection: true, max_page_size: 100 do
    argument :query, String, required: false
    argument :first, Int, required: false, default_value: 25
  end

  def users(query: nil, first: nil)
    User.query(query, page: { number: 1, size: first }).results.to_a
  end

  def orcid_from_url(url)
    Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
  end
end
