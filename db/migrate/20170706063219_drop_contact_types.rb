# frozen_string_literal: true

class DropContactTypes < ActiveRecord::Migration[4.2]
  def change
    # contact types
    remove_column :users, :is_billing_contact, :boolean, default: false
    remove_column :users, :is_voting_contact, :boolean, default: false
    remove_column :users, :is_business_contact, :boolean, default: false
    remove_column :users, :is_technical_contact, :boolean, default: false
    remove_column :users, :is_metadata_contact, :boolean, default: false
  end
end
