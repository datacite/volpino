class ChangeOrcidTokensNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :orcid_auto_update_access_token, true
    change_column_null :users, :orcid_auto_update_refresh_token, true
    change_column_null :users, :orcid_auto_update_expires_at, true
    change_column_null :users, :orcid_search_and_link_access_token, true
    change_column_null :users, :orcid_search_and_link_refresh_token, true
    change_column_null :users, :orcid_search_and_link_expires_at, true
  end
end
