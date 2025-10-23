class User < ApplicationRecord
  has_one :cart
  has_many :orders
  has_many :comments
  has_many :ratings

  # Brands pro suppliers
  has_many :brands_users
  has_many :brands, through: :brands_users

  # Role enum
  enum :role, {
    customer: "customer",
    supplier: "supplier",
    admin: "admin"
  }, default: "customer"

  validates :role, presence: true, inclusion: { in: roles.keys }
end
