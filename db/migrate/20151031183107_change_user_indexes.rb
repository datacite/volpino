class ChangeUserIndexes < ActiveRecord::Migration
  def change
    remove_index :users, name: "index_users_on_uid", column: :uid
  end
end
