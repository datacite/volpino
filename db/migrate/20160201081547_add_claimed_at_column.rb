# frozen_string_literal: true

class AddClaimedAtColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :claims, :claimed_at, :datetime
  end
end
