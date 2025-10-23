class Product < ApplicationRecord
  belongs_to :category
  belongs_to :brand, optional: true
  has_many :comments
  has_many :ratings

  validates :name, :price, presence: true
end
