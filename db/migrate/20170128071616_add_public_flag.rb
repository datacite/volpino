class AddPublicFlag < ActiveRecord::Migration
  def change
    add_column :users, :is_public, :boolean, default: true
    add_index "users", ["is_public"]
  end
end
