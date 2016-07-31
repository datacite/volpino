class ServiceSerializer < ActiveModel::Serializer
  cache key: 'service'
  attributes :id, :title, :logo_url, :summary, :description, :url, :updated

  has_many :tags

  def id
    object.name
  end

  def logo_url
    object.image_url
  end

  def updated
    object.updated_at
  end
end
