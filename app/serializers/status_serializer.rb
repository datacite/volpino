class StatusSerializer < ActiveModel::Serializer
  cache key: 'status'
  attributes :users_count, :users_new_count, :claims_search_count, :claims_auto_count, :db_size, :version, :timestamp

  def id
    object.uuid
  end
end
