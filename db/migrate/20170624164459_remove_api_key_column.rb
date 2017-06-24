class RemoveApiKeyColumn < ActiveRecord::Migration
  def change
    remove_column :users, :api_key, :boolean, default: true
  end
end
