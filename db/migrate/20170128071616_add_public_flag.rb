# frozen_string_literal: true

class AddPublicFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :is_public, :boolean, default: true
    add_index "users", ["is_public"]
  end
end
