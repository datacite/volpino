class ServiceSerializer < ActiveModel::Serializer
  cache key: 'service'
  attributes :id, :title, :logo, :summary, :description, :url, :updated

  has_many :tags

  def id
    object.name
  end

  def updated
    object.updated_at
  end
end
