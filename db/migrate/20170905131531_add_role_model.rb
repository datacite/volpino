# frozen_string_literal: true

class AddRoleModel < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :role, :role_id
  end
end
