# frozen_string_literal: true

class AddPutCodeColumn < ActiveRecord::Migration[4.2]
  def change
    add_column :claims, :put_code, :integer
    add_index "claims", ["put_code"]
  end
end
