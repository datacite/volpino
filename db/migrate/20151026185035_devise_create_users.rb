class DeviseCreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table(:users) do |t|
      t.string   :name,                   limit: 191
      t.string   :family_name,            limit: 191
      t.string   :given_names,            limit: 191
      t.string   :email,                  limit: 191
      t.string   :provider,               limit: 255
      t.string   :uid,                    limit: 191
      t.string   :authentication_token,   limit: 191
      t.string   :role,                   limit: 255, default: 'user'
      t.boolean  :auto_update,            default: true
      t.datetime :expires_at
      t.timestamps
    end

    add_index :users, :uid,               unique: true
  end
end
