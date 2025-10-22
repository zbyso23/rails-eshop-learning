FactoryBot.define do
  factory :rating do
    association :product
    association :user
    value { rand(1..5) }
  end
end
