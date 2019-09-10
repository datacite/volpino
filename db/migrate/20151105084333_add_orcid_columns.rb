class AddOrcidColumns < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :other_names, :text
    add_column :users, :api_key, :string, limit: 191

    add_index :users, [:family_name, :given_names]
  end
end
