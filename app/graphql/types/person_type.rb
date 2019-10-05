# frozen_string_literal: true

class PersonType < BaseObject
  key fields: 'id'
  
  description "A person."

  field :id, ID, null: true, description: "The ORCID ID of the person."
  field :name, String, null: true, description: "The name of the person."
  field :given_name, String, null: true, hash_key: "given_names", description: "Given name. In the U.S., the first name of a Person."
  field :family_name, String, null: true, description: "Family name. In the U.S., the last name of an Person."

  def id
    object.uid ? "https://orcid.org/#{object.uid}" : object.id
  end

  def name
    object.name
  end
end
