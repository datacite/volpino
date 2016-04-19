class AddGithubFields < ActiveRecord::Migration
  def up
    add_column :users, :github, :string, limit: 191
    add_column :users, :github_uid, :string, limit: 191
    add_column :users, :github_token, :string, limit: 191

    add_index "users", ["github"], name: "index_users_on_github", unique: true
  end

  def down
    remove_column :users, :github
    remove_column :users, :github_uid
    remove_column :users, :github_token
  end
end
