class AddGithubPutColumn < ActiveRecord::Migration
  def change
    add_column :users, :github_put_code, :integer
    add_index "users", ["github_put_code"]
  end
end
