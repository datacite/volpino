class AddUniqueClaimsIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :claims, %i[orcid doi], unique: true
  end
end
