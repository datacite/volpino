class ChangeProviderColumnType < ActiveRecord::Migration
  def change
    change_column :users, :provider_id, :string
    change_column :users, :client_id, :string
  end
end
