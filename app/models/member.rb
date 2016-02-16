class Member < ActiveRecord::Base
  has_many :users

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true

  before_validation :set_region

  scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }

  def to_param
    name
  end

  def country_name
    ISO3166::Country[country_code].name
  end

  def set_region
    write_attribute(:region, ISO3166::Country[country_code].world_region)
  end
end
