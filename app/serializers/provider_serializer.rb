class ProviderSerializer < ActiveModel::Serializer
  cache key: 'provider'

  attributes :name, :description, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end
end
