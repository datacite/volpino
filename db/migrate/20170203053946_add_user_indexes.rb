# frozen_string_literal: true

class AddUserIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index "members", ["name"]
    add_index "users", ["api_key"]
  end
end
