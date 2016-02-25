class TagSerializer < ActiveModel::Serializer
  cache key: 'tag'
  attributes :id, :title

  def id
    object.name
  end
end
