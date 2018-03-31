class UserSerializer < ActiveModel::Serializer
  # cache key: 'user'
  type 'user'

  attributes :given_names, :family_name, :name, :uid, :orcid, :github, :is_active, :created, :updated
  attribute :email, if: :can_read

  has_many :claims, if: :can_read
  belongs_to :role, serializer: RoleSerializer, if: :can_read

  def can_read
    # `scope` is current ability
    scope.can?(:read, object)
  end

  def id
    object.uid
  end

  def orcid
    "https://orcid.org/#{object.orcid}"
  end

  def github
    "https://github.com/#{object.github}" if object.github.present?
  end

  def created
    object.created_at.iso8601 if object.created_at.present?
  end

  def updated
    object.updated_at.iso8601
  end
end
