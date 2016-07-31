class MemberSerializer < ActiveModel::Serializer
  cache key: 'member'
  attributes :id, :title, :description, :member_type, :region, :country, :year, :logo_url, :email, :website, :phone, :updated

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

  def updated
    object.updated_at
  end
end
