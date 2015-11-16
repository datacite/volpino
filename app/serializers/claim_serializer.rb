class ClaimSerializer < ActiveModel::Serializer
  cache key: 'claim'
  attributes :id

  def id
    object.uuid
  end
end
