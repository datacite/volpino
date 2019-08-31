class ClaimSerializer < ActiveModel::Serializer
  cache key: 'claim'
  attributes :orcid, :doi, :source_id, :state, :claim_action, :error_messages, :put_code, :claimed, :created, :updated

  def can_read
    # `scope` is current ability
    scope.can?(:read, object)
  end

  def id
    object.uuid
  end

  def error_messages
    object.error_messages.presence
  end

  def claimed
    object.claimed_at.iso8601 if object.claimed_at.present?
  end

  def created
    object.created_at.iso8601
  end

  def updated
    object.updated_at.iso8601
  end
end
