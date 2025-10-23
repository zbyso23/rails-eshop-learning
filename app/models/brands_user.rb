class BrandsUser < ApplicationRecord
  belongs_to :brand
  belongs_to :user

  validates :user_id, uniqueness: { scope: :brand_id }
end
