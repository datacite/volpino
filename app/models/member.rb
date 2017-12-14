class Member < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :member_type, presence: true
  validates :country_code, presence: true
  validates :year, presence: true
  validates_inclusion_of :institution_type, :in => %w(national_organization academic_institution research_institution government_organization publisher association service_provider), :message => "Institution type %s is not included in the list", if: :institution_type?

  before_validation :set_region

  nilify_blanks

  scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }

  def to_param
    name
  end

  def country_name
    ISO3166::Country[country_code].name
  end

  def set_region
    if country_code.present?
      r = ISO3166::Country[country_code].world_region
    else
      r = nil
    end
    write_attribute(:region, r)
  end

  def regions
    { "AMER" => "Americas",
      "APAC" => "Asia Pacific",
      "EMEA" => "EMEA" }
  end

  def region_human_name
    regions[region]
  end

  def image_url
    "#{ENV['CDN_URL']}/images/members/#{name.downcase}.png"
  end
end
