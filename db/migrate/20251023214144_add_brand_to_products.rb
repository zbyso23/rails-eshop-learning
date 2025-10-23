class AddBrandToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :brand, foreign_key: true
  end
end
