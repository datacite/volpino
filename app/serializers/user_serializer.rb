class UserSerializer < ActiveModel::Serializer
  #cache key: 'user'
  attributes :given_names, :family_name, :credit_name, :orcid, :github, :created, :updated
  attribute :role, if: :can_read
  attribute :email, if: :can_read
  attribute :provider_id, if: :can_read
  attribute :client_id, if: :can_read
  has_many :claims, if: :can_read

  def can_read
    # `scope` is current ability
    scope.can?(:read, object)
  end

  def id
    object.uid
  end

  def orcid
    "http://orcid.org/#{object.orcid}"
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
