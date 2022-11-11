# frozen_string_literal: true

class ChangeClaimsTable < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key "claims", "users"
    remove_index "claims", name: "index_claims_user_id"

    rename_column :claims, :work_id, :doi
    remove_column :claims, :user_id
    remove_column :claims, :service_id
    add_column :claims, :uid, :string, limit: 191
    add_column :claims, :source_id, :string, limit: 191

    rename_column :status, :claims_count, :claims_search_count
    rename_column :status, :claims_new_count, :claims_search_new_count
    add_column :status, :claims_auto_count, :integer, limit: 4, default: 0
    add_column :status, :claims_auto_new_count, :integer, limit: 4, default: 0

    add_index "claims", ["uid"], name: "index_claims_uid"
    add_index "claims", ["source_id"], name: "index_claims_source_id"
  end

  def down
    remove_index "claims", name: "index_claims_uid"
    remove_index "claims", name: "index_claims_source_id"

    rename_column :claims, :doi, :work_id
    remove_column :claims, :uid
    remove_column :claims, :source_id
    add_column :claims, :service_id, :integer
    add_column :claims, :user_id, :integer, null: false

    rename_column :status, :claims_search_count, :claims_count
    rename_column :status, :claims_search_new_count, :claims_new_count
    remove_column :status, :claims_auto_count
    remove_column :status, :claims_auto_new_count

    add_index "claims", ["user_id"], name: "index_claims_user_id"
    add_foreign_key "claims", "users", name: "claims_user_id_fk", on_delete: :cascade
  end
end
