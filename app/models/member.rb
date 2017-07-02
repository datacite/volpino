class Member < ActiveRecord::Base
  has_many :users, primary_key: "name", foreign_key: "member_id"

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :member_type, presence: true
  validates :country_code, presence: true
  validates :year, presence: true

  before_validation :set_region

  nilify_blanks

  scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }

  def self.per_page
    100
  end

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
    "https://#{ENV['CDN_HOST']}/images/members/#{name.downcase}.png"
  end
end
