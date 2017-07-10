class MemberSerializer < ActiveModel::Serializer
  cache key: 'member'
  attributes :id, :title, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :created, :updated

  def can_read
    # `scope` is current ability
    scope.can?(:read, object)
  end

  def id
    object.name
  end

  def country
    object.country_name
  end

  def region
    object.region_human_name
  end

  def description
    GitHub::Markdown.render_gfm(object.description)
  end

  def logo_url
    object.image_url
  end

  def created
    object.created_at.iso8601
  end

  def updated
    object.updated_at.iso8601
  end
end
