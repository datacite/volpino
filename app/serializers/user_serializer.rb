class UserSerializer < ActiveModel::Serializer
  cache key: 'user'
  attributes :given_names, :family_name, :credit_name, :ORCID, :github, :updated
  has_many :claims

  def ORCID
    "http://orcid.org/#{object.orcid}"
  end

  def id
    "http://orcid.org/#{object.orcid}"
  end

  def github
    "https://github.com/#{object.github}" if object.github.present?
  end

  def updated
    object.updated_at
  end
end
