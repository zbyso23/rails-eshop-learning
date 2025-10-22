class Cart < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user, optional: true # optional: true, for cart for guests

  def add_product(product, quantity)
    current_item = line_items.find_by(product_id: product.id)
    if current_item
      current_item.quantity += quantity.to_i
    else
      current_item = line_items.build(product_id: product.id, quantity: quantity.to_i, price: product.price)
    end
    current_item
  end

  def total_price
    line_items.to_a.sum(&:total_price)
  end
end
