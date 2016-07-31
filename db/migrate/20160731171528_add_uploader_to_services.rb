class AddUploaderToServices < ActiveRecord::Migration
  def change
    add_column :services, :image, :string
  end
end
