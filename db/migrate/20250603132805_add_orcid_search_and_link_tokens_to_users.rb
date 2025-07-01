# frozen_string_literal: true

class AddOrcidSearchAndLinkTokensToUsers < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TABLE users ROW_FORMAT=DYNAMIC"
  end

  def change
    add_column :users, :orcid_search_and_link_access_token, :string
    add_column :users, :orcid_search_and_link_refresh_token, :string
    add_column :users, :orcid_search_and_link_expires_at, :datetime
  end

  def down
    execute "ALTER TABLE users ROW_FORMAT=COMPACT"
  end
end
