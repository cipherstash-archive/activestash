FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name  { "Doe" }
    gender { "F" }
    dob { 30.years.ago }
    title { "Ms" }
    email { "ginger@spicegirls.music" }
  end
end
