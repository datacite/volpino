class ClaimSerializer < ActiveModel::Serializer
  cache key: 'claim'
  attributes :uid, :doi, :source_id, :state

  belongs_to :uid

  def id
    object.uuid
  end

  def state
    object.human_state_name
  end
end
