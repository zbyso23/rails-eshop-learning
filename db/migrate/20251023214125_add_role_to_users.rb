class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: 'customer', null: false
    add_index :users, :role
  end
end
