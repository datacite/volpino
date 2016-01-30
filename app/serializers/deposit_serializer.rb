class DepositSerializer < ActiveModel::Serializer
  cache key: 'deposit'
  attributes :id, :state, :message_type, :message_action, :message_size, :source_token, :callback, :timestamp

  def id
    object.uuid
  end

  def state
    object.human_state_name
  end
end
