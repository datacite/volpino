# frozen_string_literal: true

class RoleSerializer < ActiveModel::Serializer
  cache key: "role"
  attributes :name, :updated

  def updated
    object.updated_at
  end
end
