# frozen_string_literal: true

class AddClaimActionIndexToClaims < ActiveRecord::Migration[8.1]
  def change
    add_index :claims, :claim_action
  end
end
