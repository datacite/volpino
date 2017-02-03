class AddUserIndexes < ActiveRecord::Migration
  def change
    add_index "members", ["name"]
    add_index "users", ["api_key"]
  end
end
