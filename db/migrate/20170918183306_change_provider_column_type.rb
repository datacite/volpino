# frozen_string_literal: true

class ChangeProviderColumnType < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :provider_id, :string
    change_column :users, :client_id, :string
  end
end
