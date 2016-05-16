class Member < ActiveRecord::Base
  has_many :users

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true

  before_validation :set_region

  scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }

  def to_param
    name
  end

  def per_page
    100
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
end
