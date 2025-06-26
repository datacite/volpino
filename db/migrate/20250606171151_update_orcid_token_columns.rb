# frozen_string_literal: true

class UpdateOrcidTokenColumns < ActiveRecord::Migration[7.1]
  def change
    # Rename existing columns
    rename_column :users, :orcid_token, :orcid_auto_update_access_token
    rename_column :users, :orcid_expires_at, :orcid_auto_update_expires_at

    # Add new columns
    add_column :users, :orcid_token, :string
    add_column :users, :orcid_expires_at, :datetime
    add_column :users, :orcid_auto_update_refresh_token, :string
  end
end
