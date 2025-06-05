class AddOrcidSearchAndLinkTokensToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :orcid_search_and_link_access_token, :string
    add_column :users, :orcid_search_and_link_refresh_token, :string
  end
end
