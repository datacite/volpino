require 'uri'

class Service < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :title, presence: true, uniqueness: true
  validates :redirect_uri, presence: true, uniqueness: true, format: { with: URI.regexp }

  def to_param
    name
  end
end