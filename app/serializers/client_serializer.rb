class ClientSerializer < ActiveModel::Serializer
  cache key: 'client'

  attributes :name, :domains, :provider_id, :year, :created, :updated

  def created
    object.created_at
  end
  
  def updated
    object.updated_at
  end
end
