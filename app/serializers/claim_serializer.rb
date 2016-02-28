class ClaimSerializer < ActiveModel::Serializer
  cache key: 'claim'
  attributes :orcid, :doi, :source_id, :state, :claimed_at

  belongs_to :orcid

  def id
    object.uuid
  end

  def state
    object.human_state_name
  end
end
