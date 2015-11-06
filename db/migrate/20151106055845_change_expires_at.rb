class ChangeExpiresAt < ActiveRecord::Migration
  def up
    change_column :users, :expires_at, :datetime, default: '1970-01-01 00:00:00', null: false
  end

  def down
    change_column :users, :expires_at, :datetime
  end
end
