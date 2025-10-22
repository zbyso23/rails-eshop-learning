class Cart < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user, optional: true # optional: true, aby košík mohli mít i hosté
end
