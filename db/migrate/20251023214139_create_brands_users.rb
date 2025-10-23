class CreateBrandsUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :brands_users do |t|
      t.references :brand, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :brands_users, [ :brand_id, :user_id ], unique: true
  end
end
