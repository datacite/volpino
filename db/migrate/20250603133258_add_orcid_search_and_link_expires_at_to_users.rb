class AddOrcidSearchAndLinkExpiresAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :orcid_search_and_link_expires_at, :string
  end
end
