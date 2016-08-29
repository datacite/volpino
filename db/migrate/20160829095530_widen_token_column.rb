class WidenTokenColumn < ActiveRecord::Migration
def up
    change_column :users, :facebook_token, :text
  end

  def down
    change_column :users, :facebook_token, :string
  end
end
