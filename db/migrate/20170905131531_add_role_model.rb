class AddRoleModel < ActiveRecord::Migration
  def change
    rename_column :users, :role, :role_id
  end
end
