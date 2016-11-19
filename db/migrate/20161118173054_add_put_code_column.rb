class AddPutCodeColumn < ActiveRecord::Migration
  def change
    add_column :claims, :put_code, :integer
    add_index "claims", ["put_code"]
  end
end
