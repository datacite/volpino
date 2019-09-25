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

  attribute :state do |object|
    object.aasm_state
  end
end
