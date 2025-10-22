FactoryBot.define do
  factory :product do
    name { "Test Product" }
    description { "Test description" }
    price { 100.0 }
    association :category
  end
end
