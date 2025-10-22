class User < ApplicationRecord
  has_many :carts
  has_many :orders
  has_many :comments
  has_many :ratings
end
