class CreateFunders < ActiveRecord::Migration[4.2]
  def change
    create_table :funders do |t|
      t.string :fundref_id
      t.string :name
      t.string :replaced

      t.timestamps null: false
    end
  end
end
