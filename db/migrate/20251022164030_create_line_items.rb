class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :price
      t.references :buyable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
