class AddDefaultProvider < ActiveRecord::Migration
  def change
    change_column_default :users, :provider, "orcid"
  end
end
