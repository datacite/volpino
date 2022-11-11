# frozen_string_literal: true

class AddClientIdColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :datacenter_id, :client_id
    rename_column :users, :member_id, :provider_id
    remove_column :users, :organization, :string
    remove_column :users, :member, :string
  end
end
