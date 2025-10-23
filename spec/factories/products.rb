FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { "Test description" }
    price { 100.0 }
    association :category
    association :brand
  end
end
