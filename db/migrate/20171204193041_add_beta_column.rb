# frozen_string_literal: true

class AddBetaColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :beta_tester, :boolean, default: false
  end
end
