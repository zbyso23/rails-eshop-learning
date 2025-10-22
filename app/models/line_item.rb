class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :buyable, polymorphic: true
end
