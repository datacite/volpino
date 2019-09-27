# frozen_string_literal: true

class UserType < BaseObject
  description "Information about users"

  field :id, ID, null: true, description: "ORCID ID"
  field :name, String, null: true, description: "User name"
  field :name_type, String, null: true, hash_key: "nameType", description: "The type of name"
  field :given_name, String, null: true, hash_key: "givenName", description: "User given name"
  field :family_name, String, null: true, hash_key: "familyName", description: "User family name"

  def id
    object.uid ? "https://orcid.org/#{object.uid}" : object.id
  end

  def name
    object.name
  end
end
