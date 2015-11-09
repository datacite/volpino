class AddStatusTable < ActiveRecord::Migration
  def change
    create_table "status", force: :cascade do |t|
      t.string   "uuid",                  limit: 191
      t.integer  "users_count",           limit: 4,   default: 0
      t.integer  "users_new_count",       limit: 4,   default: 0
      t.integer  "db_size",               limit: 8,   default: 0
      t.string   "version",               limit: 255
      t.string   "current_version",       limit: 255
      t.datetime "created_at",                                    null: false
      t.datetime "updated_at",                                    null: false
    end

    add_index "status", ["created_at"], name: "index_status_created_at"
  end
end
