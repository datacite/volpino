class ClaimSerializer < ActiveModel::Serializer
  cache key: 'claim'
  attributes :orcid, :doi, :source_id, :state, :claim_action, :claimed_at

  def id
    object.uuid
  end

  def state
    object.human_state_name
  end

  def claimed_at
    object.claimed_at.iso8601 if object.claimed_at.present?
  end
end
