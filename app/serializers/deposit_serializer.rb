class DepositSerializer < ActiveModel::Serializer
  cache key: 'deposit'
  attributes :id, :state, :message_type, :message_action, :source_token, :callback, :timestamp

  def id
    object.uuid
  end
end
