class AddSandboxId < ActiveRecord::Migration
  def change
    add_column :users, :sandbox_id, :string
  end
end
