class FunderSerializer < ActiveModel::Serializer
  attributes :fundref_id, :name, :replaced, :updated_at

  def id
    object.fundref_id
  end

  def name
    object.name
  end

  def updated
    object.updated_at
  end

end
