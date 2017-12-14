class AddInstitutionTypeColumn < ActiveRecord::Migration
  def change
    add_column :members, :institution_type, :string, limit: 191
    add_index :members, [:institution_type], name: "index_member_institution_type"
  end
end
