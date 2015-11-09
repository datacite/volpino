class ServiceSerializer < ActiveModel::Serializer
  cache key: 'service'
  attributes :id, :title, :redirect_uri

  def id
    object.name
  end
end
