# frozen_string_literal: true

class RemoveFacebookFields < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :facebook_uid, :string, limit: 191
    remove_column :users, :facebook_token, :text, limit: 65535
  end
end
