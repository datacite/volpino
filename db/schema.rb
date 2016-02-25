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

ActiveRecord::Schema.define(version: 20160225214743) do

  create_table "claims", force: :cascade do |t|
    t.string   "uuid",        limit: 191
    t.string   "doi",         limit: 191
    t.integer  "state",       limit: 4,   default: 0
    t.string   "state_event", limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "uid",         limit: 191
    t.string   "source_id",   limit: 191
    t.datetime "claimed_at"
  end

  add_index "claims", ["created_at"], name: "index_claims_created_at", using: :btree
  add_index "claims", ["source_id"], name: "index_claims_source_id", using: :btree
  add_index "claims", ["uid"], name: "index_claims_uid", using: :btree

  create_table "deposits", force: :cascade do |t|
    t.string   "uuid",           limit: 191,                           null: false
    t.string   "message_type",   limit: 255,                           null: false
    t.text     "message",        limit: 4294967295
    t.string   "source_token",   limit: 191
    t.text     "callback",       limit: 65535
    t.integer  "state",          limit: 4,          default: 0
    t.string   "state_event",    limit: 191
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "message_action", limit: 255,        default: "create", null: false
  end

  add_index "deposits", ["source_token"], name: "index_deposits_on_source_token", using: :btree
  add_index "deposits", ["updated_at"], name: "index_deposits_on_updated_at", using: :btree
  add_index "deposits", ["uuid"], name: "index_deposits_on_uuid", using: :btree

  create_table "members", force: :cascade do |t|
    t.string   "name",         limit: 191,                    null: false
    t.string   "title",        limit: 255,                    null: false
    t.text     "description",  limit: 65535
    t.string   "member_type",  limit: 191,   default: "full"
    t.integer  "year",         limit: 4
    t.string   "region",       limit: 255
    t.string   "country_code", limit: 255
    t.string   "logo",         limit: 255
    t.string   "email",        limit: 255
    t.string   "website",      limit: 255
    t.string   "phone",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: :cascade do |t|
    t.string   "name",         limit: 255,   null: false
    t.string   "title",        limit: 255,   null: false
    t.text     "redirect_uri", limit: 255,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo",         limit: 191
    t.string   "url",          limit: 255
    t.text     "summary",      limit: 65535
    t.text     "description",  limit: 65535
  end

  create_table "services_tags", id: false, force: :cascade do |t|
    t.integer "service_id", limit: 4
    t.integer "tag_id",     limit: 4
  end

  create_table "status", force: :cascade do |t|
    t.string   "uuid",                    limit: 191
    t.integer  "users_count",             limit: 4,   default: 0
    t.integer  "users_new_count",         limit: 4,   default: 0
    t.integer  "db_size",                 limit: 8,   default: 0
    t.string   "version",                 limit: 255
    t.string   "current_version",         limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "claims_search_count",     limit: 4,   default: 0
    t.integer  "claims_search_new_count", limit: 4,   default: 0
    t.integer  "claims_auto_count",       limit: 4,   default: 0
    t.integer  "claims_auto_new_count",   limit: 4,   default: 0
    t.integer  "members_emea_count",      limit: 4,   default: 0
    t.integer  "members_amer_count",      limit: 4,   default: 0
    t.integer  "members_apac_count",      limit: 4,   default: 0
  end

  add_index "status", ["created_at"], name: "index_status_created_at", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",       limit: 191, null: false
    t.string   "title",      limit: 191, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "tags", ["name"], name: "index_tags_on_name", using: :btree

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
    t.integer  "member_id",            limit: 4
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["family_name", "given_names"], name: "index_users_on_family_name_and_given_names", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
