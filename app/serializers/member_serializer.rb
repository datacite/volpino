class MemberSerializer < ActiveModel::Serializer
  require 'active_support/core_ext/string'

  cache key: 'member'
  attributes :id, :title, :description, :region, :country, :year

  def id
    object.name
  end

  def country
    object.country_name
  end
end
