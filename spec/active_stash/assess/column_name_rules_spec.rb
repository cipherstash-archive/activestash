RSpec.describe ActiveStash::Assess::ColumnNameRules do
  describe ".check" do
    [
      [%w(name), "names"],
      [%w(lastname lname surname), "last names"],
      [%w(phone phonenumber), "phone numbers"],
      [%w(dateofbirth birthday dob), "dates of birth"],
      [%w(zip zipcode postalcode), "postal codes"],
      [%w(accesstoken refreshtoken), "OAuth tokens"],
    ].each do |field_names, expected_display_name|
      it "finds a match for all fields given #{field_names.inspect}" do
        matches = described_class.check(field_names)
        expect(matches.keys.sort).to eq(field_names.sort)
      end

      field_names.each do |field_name|
        it "returns display name #{expected_display_name.inspect} for field name #{field_name.inspect}" do
          matches = described_class.check(field_names)
          expect(matches[field_name].first[:display_name]).to eq(expected_display_name)
        end
      end
    end
  end
end
