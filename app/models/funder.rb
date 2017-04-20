class Funder < ActiveRecord::Base

    validates :fundref_id, presence: true, uniqueness: true


    scope :query, ->(query) { where("name like ? OR title like ?", "%#{query}%", "%#{query}%") }


    # def to_param
    #   name
    # end
    #
    # def fundref_id
    #   fundref_id
    # end


    def image_url
      "https://#{ENV['CDN_HOST']}/images/funders/#{name.downcase}.png"
    end
  end
