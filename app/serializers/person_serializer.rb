class PersonSerializer < ActiveModel::Serializer
  cache key: 'person'
  type 'people'
  attributes :given, :family, :literal, :orcid, :github, :updated

  def id
    object.uid
  end

  def orcid
    "http://orcid.org/#{object.orcid}"
  end

  def literal
    [object.given_names, object.family_name].join(" ").presence || object.name.presence || "http://orcid.org/#{object.orcid}"
  end

  def given
    object.given_names.presence
  end

  def family
    object.family_name.presence
  end

  def updated
    object.updated_at
  end
end
