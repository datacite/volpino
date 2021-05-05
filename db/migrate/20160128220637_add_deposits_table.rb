class AddDepositsTable < ActiveRecord::Migration[4.2]
  def change
    create_table "deposits", force: :cascade do |t|
      t.string   "uuid",           limit: 191,                           null: false
      t.string   "message_type",   limit: 255,                           null: false
      t.text     "message",        limit: 4294967295
      t.string   "source_token",   limit: 191
      t.text     "callback",       limit: 65535
      t.integer  "state",          limit: 4, default: 0
      t.string   "state_event",    limit: 191
      t.datetime "created_at",                                           null: false
      t.datetime "updated_at",                                           null: false
      t.string   "message_action", limit: 255, default: "create", null: false
    end

    add_index "deposits", ["uuid"], name: "index_deposits_on_uuid"
    add_index "deposits", ["source_token"], name: "index_deposits_on_source_token"
    add_index "deposits", ["updated_at"], name: "index_deposits_on_updated_at"
  end
end
