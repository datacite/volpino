# frozen_string_literal: true

class AddUploaderToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :image, :string
  end
end
