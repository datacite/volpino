# frozen_string_literal: true

class ClaimSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :claims
  set_id :uuid

  attributes :orcid, :doi, :source_id, :state, :claim_action, :error_messages, :put_code, :claimed, :created, :updated

  belongs_to :user, serializer: UserSerializer, record_type: :users

  attribute :doi do |object|
    "https://doi.org/#{object.doi}"
  end

  attribute :orcid do |object|
    "https://orcid.org/#{object.user_id}"
  end

  attribute :error_messages do |object|
    if object.error_messages.is_a?(String)
      eval(object.error_messages)
    else
      Array.wrap(object.error_messages)
    end
  end

  attribute :state, &:aasm_state
end
