class UserSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :users
  set_id :uid
  
  attributes :given_name, :family_name, :name, :orcid, :github, :role_id, :is_active, :created, :updated
  attribute :email, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read, object) == true }

  has_many :claims, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read, object) == true }
  
  attribute :orcid do |object|
    "https://orcid.org/#{object.uid}"
  end

  attribute :github do |object|
    "https://github.com/#{object.github}" if object.github.present?
  end
end
