# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160112182305) do

  create_table "claims", force: :cascade do |t|
    t.string   "uuid",        limit: 191
    t.integer  "user_id",     limit: 4,               null: false
    t.string   "work_id",     limit: 191
    t.integer  "service_id",  limit: 4
    t.integer  "state",       limit: 4,   default: 0
    t.string   "state_event", limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "claims", ["created_at"], name: "index_claims_created_at", using: :btree
  add_index "claims", ["user_id"], name: "index_claims_user_id", using: :btree

  create_table "services", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.string   "title",        limit: 255, null: false
    t.text     "redirect_uri", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "status", force: :cascade do |t|
    t.string   "uuid",             limit: 191
    t.integer  "users_count",      limit: 4,   default: 0
    t.integer  "users_new_count",  limit: 4,   default: 0
    t.integer  "db_size",          limit: 8,   default: 0
    t.string   "version",          limit: 255
    t.string   "current_version",  limit: 255
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "claims_count",     limit: 4,   default: 0
    t.integer  "claims_new_count", limit: 4,   default: 0
  end

  add_index "status", ["created_at"], name: "index_status_created_at", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                 limit: 191
    t.string   "family_name",          limit: 191
    t.string   "given_names",          limit: 191
    t.string   "email",                limit: 191
    t.string   "provider",             limit: 255
    t.string   "uid",                  limit: 191
    t.string   "authentication_token", limit: 191
    t.string   "role",                 limit: 255,   default: "user"
    t.boolean  "auto_update",                        default: true
    t.datetime "expires_at",                         default: '1970-01-01 00:00:00', null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "other_names",          limit: 65535
    t.string   "api_key",              limit: 191
    t.string   "confirmation_token",   limit: 191
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",    limit: 255
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["family_name", "given_names"], name: "index_users_on_family_name_and_given_names", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

  add_foreign_key "claims", "users", name: "claims_user_id_fk", on_delete: :cascade
end
