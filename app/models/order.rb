class Order < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user

  def self.create_from_cart(cart, user)
    # Create order only from cart what is not empty
    return nil if cart.nil? || cart.line_items.empty?

    order = new(user: user, total_price: cart.total_price, status: "pending")
    cart.line_items.each do |line_item|
      order.line_items.build(
        product: line_item.product,
        quantity: line_item.quantity,
        price: line_item.price
      )
    end

    if order.save
      cart.destroy! # Rmove cart after create orader
      order
    else
      nil
    end
  end
end
