# frozen_string_literal: true

class RemoveApiKeyColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :api_key, :boolean, default: true
  end
end
