# frozen_string_literal: true

class AddContactTypeColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :member_id, :member
    add_column :users, :member_id, :string
    add_column :users, :datacenter_id, :string
    add_column :users, :organization, :string

    # contact types
    add_column :users, :is_billing_contact, :boolean, default: false
    add_column :users, :is_voting_contact, :boolean, default: false
    add_column :users, :is_business_contact, :boolean, default: false
    add_column :users, :is_technical_contact, :boolean, default: false
    add_column :users, :is_metadata_contact, :boolean, default: false
  end
end
