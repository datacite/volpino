class AddClientIdColumn < ActiveRecord::Migration
  def change
    rename_column :users, :datacenter_id, :client_id
    rename_column :users, :member_id, :provider_id
    remove_column :users, :organization, :string
    remove_column :users, :member, :string
  end
end
