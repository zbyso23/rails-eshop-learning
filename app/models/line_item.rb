class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :buyable, polymorphic: true

  def total_price
    price * quantity
  end
end
