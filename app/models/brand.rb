class Brand < ApplicationRecord
  has_many :products
  has_many :brands_users
  has_many :users, through: :brands_users

  validates :name, presence: true, uniqueness: true
end
