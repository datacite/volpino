class AddSandboxId < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :sandbox_id, :string
  end
end
