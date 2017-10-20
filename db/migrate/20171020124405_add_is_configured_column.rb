class AddIsConfiguredColumn < ActiveRecord::Migration
  def change
    add_column :users, :is_not_configured, :boolean, default: true
  end
end
