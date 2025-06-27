# frozen_string_literal: true

class AddOrcidSearchAndLinkTokensToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :orcid_search_and_link_access_token, :text
    add_column :users, :orcid_search_and_link_refresh_token, :text
    add_column :users, :orcid_search_and_link_expires_at, :datetime
  end
end
