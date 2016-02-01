class AddClaimedAtColumn < ActiveRecord::Migration
  def change
    add_column :claims, :claimed_at, :datetime
  end
end
