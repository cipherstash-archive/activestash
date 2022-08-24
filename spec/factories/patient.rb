
FactoryBot.define do
  factory :patient do
    height { Faker::Number.between(from: 100, to: 200) }
    weight { Faker::Number.between(from: 35, to: 200) }
  end
end
