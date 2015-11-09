class StatusSerializer < ActiveModel::Serializer
  cache key: 'status'
  attributes :id, :users_count, :users_new_count, :db_size, :version, :timestamp

  def id
    object.uuid
  end
end
