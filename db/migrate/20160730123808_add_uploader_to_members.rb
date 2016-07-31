class AddUploaderToMembers < ActiveRecord::Migration
  def change
    add_column :members, :image, :string
  end
end
