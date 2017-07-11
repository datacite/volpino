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

ActiveRecord::Schema.define(version: 20170710050348) do

  create_table "claims", force: :cascade do |t|
    t.string   "uuid",           limit: 191
    t.string   "doi",            limit: 191
    t.integer  "state",          limit: 4,     default: 0
    t.string   "state_event",    limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "orcid",          limit: 191
    t.string   "source_id",      limit: 191
    t.datetime "claimed_at"
    t.text     "error_messages", limit: 65535
    t.string   "claim_action",   limit: 191,   default: "create"
    t.integer  "put_code",       limit: 4
  end

  add_index "claims", ["created_at"], name: "index_claims_created_at", using: :btree
  add_index "claims", ["orcid"], name: "index_claims_uid", using: :btree
  add_index "claims", ["put_code"], name: "index_claims_on_put_code", using: :btree
  add_index "claims", ["source_id"], name: "index_claims_source_id", using: :btree

  create_table "funders", force: :cascade do |t|
    t.string   "fundref_id", limit: 255
    t.string   "name",       limit: 255
    t.string   "replaced",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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
    t.string   "image",        limit: 255
  end

  add_index "members", ["name"], name: "index_members_on_name", using: :btree

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
    t.boolean  "skip_info",                          default: false
    t.string   "confirmation_token",   limit: 191
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",    limit: 255
    t.integer  "member",               limit: 4
    t.string   "github",               limit: 191
    t.string   "github_uid",           limit: 191
    t.string   "github_token",         limit: 191
    t.string   "facebook_uid",         limit: 191
    t.text     "facebook_token",       limit: 65535
    t.string   "google_uid",           limit: 191
    t.string   "google_token",         limit: 191
    t.integer  "github_put_code",      limit: 4
    t.boolean  "is_public",                          default: true
    t.string   "member_id",            limit: 255
    t.string   "datacenter_id",        limit: 255
    t.string   "organization",         limit: 255
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["family_name", "given_names"], name: "index_users_on_family_name_and_given_names", using: :btree
  add_index "users", ["github"], name: "index_users_on_github", unique: true, using: :btree
  add_index "users", ["github_put_code"], name: "index_users_on_github_put_code", using: :btree
  add_index "users", ["is_public"], name: "index_users_on_is_public", using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
