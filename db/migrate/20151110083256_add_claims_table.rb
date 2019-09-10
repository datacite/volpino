class AddClaimsTable < ActiveRecord::Migration[4.2]
  def change
    create_table "claims", force: :cascade do |t|
      t.string   "uuid",         limit: 191
      t.integer  "user_id",                                       null: false
      t.string   "work_id",      limit: 191
      t.integer  "service_id"
      t.integer  "state",        limit: 4,        default: 0
      t.string   "state_event",  limit: 255
      t.datetime "created_at",                                    null: false
      t.datetime "updated_at",                                    null: false
    end

    add_index "claims", ["created_at"], name: "index_claims_created_at"
    add_index "claims", ["user_id"], name: "index_claims_user_id"

    add_foreign_key "claims", "users", name: "claims_user_id_fk", on_delete: :cascade

    add_column :status, :claims_count, :integer, limit: 4, default: 0
    add_column :status, :claims_new_count, :integer, limit: 4, default: 0
  end
end
