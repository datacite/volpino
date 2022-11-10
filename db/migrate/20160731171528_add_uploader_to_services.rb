# frozen_string_literal: true

class AddUploaderToServices < ActiveRecord::Migration[4.2]
  def change
    add_column :services, :image, :string
  end
end
