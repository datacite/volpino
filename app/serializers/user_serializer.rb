class UserSerializer < ActiveModel::Serializer
  cache key: 'user'
  attributes :given_names, :family_name, :ORCID

  def ORCID
    object.orcid
  end

  def id
    object.orcid
  end
end
