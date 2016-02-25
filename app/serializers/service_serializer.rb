class ServiceSerializer < ActiveModel::Serializer
  cache key: 'service'
  attributes :id, :title, :logo, :summary, :description, :url, :redirect_uri

  has_many :tags

  def id
    object.name
  end
end
