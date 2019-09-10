class AddMembersTable < ActiveRecord::Migration[4.2]
  def change
    create_table "members", force: :cascade do |t|
      t.string   "name",         limit: 191, null: false
      t.string   "title",        limit: 255, null: false
      t.text     "description",  limit: 65535
      t.string   "member_type",  limit: 191, default: "full"
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

    add_column :users, :member_id, :integer
    add_column :status, :members_emea_count, :integer, default: 0
    add_column :status, :members_amer_count, :integer, default: 0
    add_column :status, :members_apac_count, :integer, default: 0
  end
end
