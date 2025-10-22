class Order < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user
end
