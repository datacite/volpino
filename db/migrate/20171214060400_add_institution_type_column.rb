# frozen_string_literal: true

class AddInstitutionTypeColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :institution_type, :string, limit: 191
    add_index :members, [:institution_type], name: "index_member_institution_type"
  end
end
