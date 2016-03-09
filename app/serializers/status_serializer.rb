class StatusSerializer < ActiveModel::Serializer
  cache key: 'status'
  attributes :users_count, :users_new_count, :members_count, :claims_search_count, :claims_search_new_count, :claims_auto_count, :claims_auto_new_count, :db_size, :version, :timestamp

  def id
    object.uuid
  end
end
