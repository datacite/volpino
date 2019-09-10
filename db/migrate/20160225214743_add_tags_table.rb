class AddTagsTable < ActiveRecord::Migration[4.2]
  def change
    create_table "services_tags", id: false, force: :cascade do |t|
      t.integer "service_id", limit: 4
      t.integer "tag_id",     limit: 4
    end

    create_table "tags", force: :cascade do |t|
      t.string   "name",       limit: 191, null: false
      t.string   "title",      limit: 191, null: false
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
    end

    add_index "tags", ["name"], name: "index_tags_on_name"

    add_column :services, :logo, :string, limit: 191
    add_column :services, :url, :string
    add_column :services, :summary, :text, limit: 65535
    add_column :services, :description, :text, limit: 65535
  end
end
