class AddAutoUpdateOption < ActiveRecord::Migration
  def change
    add_column :users, :auto_update, :boolean, default: true
    add_column :users, :expires_at, :datetime
  end
end
