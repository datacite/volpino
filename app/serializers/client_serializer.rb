class ClientSerializer < ActiveModel::Serializer
  cache key: 'client'

  attributes :name, :domains, :provider_id, :year, :created, :updated

  belongs_to :provider, serializer: ProviderSerializer

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
