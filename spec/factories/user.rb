FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email { Faker::Internet.email }
    title { Faker::Name.prefix }
    gender { Faker::Gender.type }
    dob { Faker::Date.birthday(min_age: 18, max_age: 65) }

    patient
    medicare_card
  end
end
