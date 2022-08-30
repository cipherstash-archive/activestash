RSpec.describe ActiveStash::Assess::ColumnNameRules do
  describe ".check" do
    [
      ["name", "names", "AS0001"],
      ["names", "names", "AS0001"],
      ["lastname", "names", "AS0001"],
      ["last_name", "names", "AS0001"],
      ["last_names", "names", "AS0001"],
      ["lname", "names", "AS0001"],
      ["surname", "names", "AS0001"],
      ["firstname", "names", "AS0001"],
      ["first_name", "names", "AS0001"],
      ["fname", "names", "AS0001"],
      ["phone", "phone numbers", "AS0001"],
      ["phone_number", "phone numbers", "AS0001"],
      ["date_of_birth", "dates of birth", "AS0001"],
      ["birthday", "dates of birth", "AS0001"],
      ["dob", "dates of birth", "AS0001"],
      ["address", "addresses", "AS0001"],
      ["city", "addresses", "AS0001"],
      ["state", "addresses", "AS0001"],
      ["county", "addresses", "AS0001"],
      ["country", "addresses", "AS0001"],
      ["zip", "addresses", "AS0001"],
      ["zip_code", "addresses", "AS0001"],
      ["postal_code", "addresses", "AS0001"],
      ["postal", "addresses", "AS0001"],
      ["post_code", "addresses", "AS0001"],
      ["access_token", "OAuth tokens", "AS0004"],
      ["refresh_token", "OAuth tokens", "AS0004"],
      ["ip", "IP addresses", "AS0001"],
      ["ip_address", "IP addresses", "AS0001"],
      ["ccn", "credit card numbers", "AS0003"],
      ["credit_card_number", "credit card numbers", "AS0003"],
      ["ssn", "social security numbers", "AS0001"],
      ["social_security_number", "social security numbers", "AS0001"],
      ["gender", "genders", "AS0001"],
      ["nationality", "nationalities", "AS0001"],
      ["tfn", "tax file numbers", "AS0003"],
      ["tax_file_number", "tax file numbers", "AS0003"],
      ["medicare_number", "medicare numbers", "AS0002"],
    ].each do |field_name, expected_display_name, expected_error_code|
      it "finds a match given field name: #{field_name.inspect}" do
        matches = described_class.check([field_name])
        expect(matches).to have_key(field_name)
      end

      it "matches for #{field_name.inspect} have the display name #{expected_display_name.inspect}" do
        matches = described_class.check([field_name])
        expect(matches[field_name].first[:display_name]).to eq(expected_display_name)
      end

      it "matches for #{field_name.inspect} have the error code #{expected_error_code.inspect}" do
        matches = described_class.check([field_name])
        expect(matches[field_name].first[:error_code]).to eq(expected_error_code)
      end
    end
  end
end
