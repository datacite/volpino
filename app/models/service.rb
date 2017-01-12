require 'uri'

class Service < ActiveRecord::Base
  has_and_belongs_to_many :tags

  nilify_blanks

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true, format: { with: URI.regexp }
  validates :redirect_uri, format: { with: URI.regexp }, allow_blank: true

  scope :query, ->(query) { where("name like ? OR title like ? or description like ?", "%#{query}%", "%#{query}%", "%#{query}%") }

  def to_param
    name
  end

  def image_url
    "https://#{ENV['CDN_HOST']}/images/services/#{name.downcase}.png"
  end
end
