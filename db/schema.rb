# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_06_085208) do
  create_table "claims", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "aasm_state", limit: 191
    t.string "claim_action", limit: 191, default: "create"
    t.datetime "claimed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "doi", limit: 191
    t.text "error_messages"
    t.string "orcid", limit: 191
    t.integer "put_code"
    t.string "source_id", limit: 191
    t.integer "state_number", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.string "uuid", limit: 191
    t.index ["created_at"], name: "index_claims_created_at"
    t.index ["orcid"], name: "index_claims_uid"
    t.index ["put_code"], name: "index_claims_on_put_code"
    t.index ["source_id"], name: "index_claims_source_id"
    t.index ["updated_at", "aasm_state"], name: "index_claims_on_updated_state"
  end

  create_table "funders", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "fundref_id"
    t.string "name"
    t.string "replaced"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "members", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "country_code"
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "email"
    t.string "image"
    t.string "institution_type", limit: 191
    t.string "logo"
    t.string "member_type", limit: 191, default: "full"
    t.string "name", limit: 191, null: false
    t.string "phone"
    t.string "region"
    t.string "title", null: false
    t.datetime "updated_at", precision: nil
    t.string "website"
    t.integer "year"
    t.index ["institution_type"], name: "index_member_institution_type"
    t.index ["name"], name: "index_members_on_name"
  end

  create_table "status", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "claims_auto_count", default: 0
    t.integer "claims_auto_new_count", default: 0
    t.integer "claims_search_count", default: 0
    t.integer "claims_search_new_count", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.string "current_version"
    t.bigint "db_size", default: 0
    t.integer "members_amer_count", default: 0
    t.integer "members_apac_count", default: 0
    t.integer "members_emea_count", default: 0
    t.datetime "updated_at", precision: nil, null: false
    t.integer "users_count", default: 0
    t.integer "users_new_count", default: 0
    t.string "uuid", limit: 191
    t.string "version"
    t.index ["created_at"], name: "index_status_created_at"
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "authentication_token", limit: 191
    t.boolean "auto_update", default: true
    t.boolean "beta_tester", default: false
    t.string "client_id"
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token", limit: 191
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.string "email", limit: 191
    t.datetime "expires_at", precision: nil, default: "1970-01-01 00:00:00", null: false
    t.string "family_name", limit: 191
    t.string "github", limit: 191
    t.integer "github_put_code"
    t.string "github_token", limit: 191
    t.string "github_uid", limit: 191
    t.string "given_names", limit: 191
    t.boolean "is_public", default: true
    t.string "name", limit: 191
    t.string "orcid_auto_update_access_token", limit: 191
    t.datetime "orcid_auto_update_expires_at", precision: nil, default: "1970-01-01 00:00:00"
    t.string "orcid_auto_update_refresh_token"
    t.datetime "orcid_expires_at"
    t.string "orcid_search_and_link_access_token"
    t.datetime "orcid_search_and_link_expires_at"
    t.string "orcid_search_and_link_refresh_token"
    t.string "orcid_token"
    t.string "organization", limit: 191
    t.text "other_names"
    t.string "provider", default: "orcid"
    t.string "provider_id"
    t.string "role_id", default: "user"
    t.string "sandbox_id"
    t.string "uid", limit: 191
    t.string "unconfirmed_email"
    t.datetime "updated_at", precision: nil
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["family_name", "given_names"], name: "index_users_on_family_name_and_given_names"
    t.index ["github"], name: "index_users_on_github", unique: true
    t.index ["github_put_code"], name: "index_users_on_github_put_code"
    t.index ["is_public"], name: "index_users_on_is_public"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end
end
