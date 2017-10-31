class OrcidUserSerializer < ActiveModel::Serializer
  cache key: 'orcid_user'

  attributes :given_names, :family_name, :name, :orcid, :updated

  def orcid
    "https://orcid.org/#{object.id}"
  end

  def updated
    object.updated_at
  end
end
