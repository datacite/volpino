class RemoveTagsTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :tags
    drop_table :services
    drop_table :services_tags
  end

  def down
    create_table "tags", force: :cascade do |t|
      t.string   "name",       limit: 191, null: false
      t.string   "title",      limit: 191, null: false
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
    end

    add_index "tags", ["name"], name: "index_tags_on_name"

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
      t.string   "image",        limit: 255
    end

    create_table "services_tags", id: false, force: :cascade do |t|
      t.integer "service_id", limit: 4
      t.integer "tag_id",     limit: 4
    end
  end
end
