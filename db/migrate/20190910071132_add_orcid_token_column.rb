# frozen_string_literal: true

class AddOrcidTokenColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :organization, :string, limit: 191

    add_column :users, :orcid_token, :string, limit: 191
    add_column :users, :orcid_expires_at, :datetime, default: "1970-01-01 00:00:00", null: false

    remove_column :users, :google_uid, :string, limit: 191
    remove_column :users, :google_token, :string, limit: 191
  end
end
