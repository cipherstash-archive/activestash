
FactoryBot.define do
  factory :medicare_card do
    medicare_number { Faker::IDNumber.valid }
    expiry_date { Faker::Date.between(from: 1.year.ago, to: 10.years.from_now) }
  end
end
