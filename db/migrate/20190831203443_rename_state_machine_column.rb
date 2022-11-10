# frozen_string_literal: true

class RenameStateMachineColumn < ActiveRecord::Migration[5.2]
  def change
    rename_column :claims, :state, :state_number
    remove_column :claims, :state_event, :string, limit: 191
  end
end
