# frozen_string_literal: true

class AddOrcidTokensToUsers < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TABLE users ROW_FORMAT=DYNAMIC"
  end

  def change
    # Rename existing ORCID columns to be the auto-update columns
    rename_column :users, :orcid_token, :orcid_auto_update_access_token
    rename_column :users, :orcid_expires_at, :orcid_auto_update_expires_at
    add_column :users, :orcid_auto_update_refresh_token, :string, null: true

    # Make sure the auto-update columns are nullable
    change_column_null :users, :orcid_auto_update_access_token, true
    change_column_null :users, :orcid_auto_update_expires_at, true

    # Add new columns for ORCID to replace the renamed columns
    add_column :users, :orcid_token, :string, null: true
    add_column :users, :orcid_expires_at, :datetime, null: true

    # Add search and link columns
    add_column :users, :orcid_search_and_link_access_token, :string, null: true
    add_column :users, :orcid_search_and_link_refresh_token, :string, null: true
    add_column :users, :orcid_search_and_link_expires_at, :datetime, null: true
  end

  def down
    execute "ALTER TABLE users ROW_FORMAT=COMPACT"
  end
end
