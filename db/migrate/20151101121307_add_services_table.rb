# frozen_string_literal: true

class AddServicesTable < ActiveRecord::Migration[4.2]
  def change
    create_table "services", force: :cascade do |t|
      t.string   "name",         limit: 255, null: false
      t.string   "title",        limit: 255, null: false
      t.text     "redirect_uri", limit: 255, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
