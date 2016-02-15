class Member < ActiveRecord::Base
  has_many :users

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true

  scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }

  def to_param
    name
  end

  def country_name
    country = ISO3166::Country[country_code]
    country.translations[I18n.locale.to_s] || country.name
  end
end
