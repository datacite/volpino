# frozen_string_literal: true

class AddAasmstateColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :claims, :aasm_state, :string, limit: 191
    add_index :claims, %i[updated_at aasm_state], name: "index_claims_on_updated_state"
  end
end
