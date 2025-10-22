class User < ApplicationRecord
  has_one :cart
  has_many :orders
  has_many :comments
  has_many :ratings
end
