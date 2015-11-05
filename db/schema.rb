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

ActiveRecord::Schema.define(version: 20151105084333) do

  create_table "services", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.string   "title",        limit: 255, null: false
    t.text     "redirect_uri", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "other_names",          limit: 65535
    t.string   "api_key",              limit: 191
    t.boolean  "skip_info",                          default: false
  end

  add_index "users", ["family_name", "given_names"], name: "index_users_on_family_name_and_given_names", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
