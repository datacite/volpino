# frozen_string_literal: true

class AddGithubPutColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :github_put_code, :integer
    add_index "users", ["github_put_code"]
  end
end
