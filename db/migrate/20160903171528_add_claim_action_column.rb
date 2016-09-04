class AddClaimActionColumn < ActiveRecord::Migration
  def up
    add_column :claims, :claim_action, :string, limit: 191, default: "create"
    remove_index "claims", ["orcid", "doi"]
  end

  def down
    remove_column :claims, :claim_action
  end
end
