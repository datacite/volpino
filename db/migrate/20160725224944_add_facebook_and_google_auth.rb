class AddFacebookAndGoogleAuth < ActiveRecord::Migration
  def up
    add_column :users, :facebook_uid, :string, limit: 191
    add_column :users, :facebook_token, :string, limit: 191
    add_column :users, :google_uid, :string, limit: 191
    add_column :users, :google_token, :string, limit: 191
  end

  def down
    remove_column :users, :facebook_uid
    remove_column :users, :facebook_token
    remove_column :users, :google_uid
    remove_column :users, :google_token
  end
end
