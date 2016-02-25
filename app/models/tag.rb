class Tag < ActiveRecord::Base
  has_and_belongs_to_many :services

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true, uniqueness: true

  scope :query, ->(query) { where("name = ?", query) }

  def to_param
    name
  end
end
