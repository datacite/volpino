class WidenTokenColumn < ActiveRecord::Migration[4.2]
def up
    change_column :users, :facebook_token, :text
  end

  def down
    change_column :users, :facebook_token, :string
  end
end
