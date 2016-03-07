class AddUniqueClaimsIndex < ActiveRecord::Migration
  def change
    add_index :claims, [:orcid, :doi], unique: true
  end
end
