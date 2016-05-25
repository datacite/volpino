class TagSerializer < ActiveModel::Serializer
  cache key: 'tag'
  attributes :id, :title, :updated

  def id
    object.name
  end

  def updated
    object.updated_at
  end
end
