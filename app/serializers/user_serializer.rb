class UserSerializer < ActiveModel::Serializer
  cache key: 'user'
  attributes :given_names, :family_name, :credit_name, :orcid, :github, :role, :email, :member_id, :data_center_id, :claims, :created, :updated

  def id
    object.uid
  end

  def orcid
    "http://orcid.org/#{object.orcid}"
  end

  def data_center_id
    object.datacenter_id
  end

  def github
    "https://github.com/#{object.github}" if object.github.present?
  end

  def created
    object.created_at.iso8601
  end

  def updated
    object.updated_at.iso8601
  end
end
