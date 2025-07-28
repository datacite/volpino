# frozen_string_literal: true

class AlterRowSizeDynamic < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TABLE users ROW_FORMAT=DYNAMIC"
  end

  def down
    execute "ALTER TABLE users ROW_FORMAT=COMPACT"
  end
end
