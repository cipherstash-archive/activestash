RSpec.describe ActiveStash::Assess::NameRules do
  describe ".check" do
    %w(
      name lastname lname surname
      phone phonenumber
      dateofbirth birthday dob
      zip zipcode postalcode
      accesstoken refreshtoken
    ).each do |field_name|
      it "finds a match given '#{field_name}' in field names" do
        matches = described_class.check([field_name])
        expect(matches).to have_key(field_name)
      end
    end
  end
end
