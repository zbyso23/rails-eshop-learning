class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.decimal :total_price
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
