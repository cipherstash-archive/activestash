require_relative "../support/user"
require_relative "../support/user3"
require_relative "../support/migrations/create_users3"


RSpec.describe "ActiveStash::Validations" do
  before do
    User.collection.create!
    User.delete_all
  end

  after do
    User.delete_all
    User.collection.drop!
  end

  describe "when no user with a given email address exists" do
    it "allows the creation of a new user" do
      expect {
        create(:user, email: "person@example.net")
      }.to_not raise_error
    end
  end

  describe "when a user with a given email address exists" do
    before { create(:user, email: "person@example.net") }

    it "creation of a new user with the same email fails" do
      expect {
        create(:user, email: "person@example.net")
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email already exists")
    end

    it "if validation is skipped then creation of a new user succeeds" do
      expect {
        user = build(:user, email: "person@example.net")
        user.skip_validations = true
        user.save!
      }.to_not raise_error
    end
  end
end

RSpec.describe "Unique validations on a field that has not been indexed into CipherStash" do
  before(:all) do
    CreateUsers3.migrate(:up)
  end

  after(:all) do
    CreateUsers3.migrate(:down)
  end

  before(:each) do
    User3.collection.create!
    User3.delete_all
  end

  after(:each) do
    User3.delete_all
    User3.collection.drop!
  end

  describe "when no user with a given first name address exists" do
    it "allows the creation of a new user" do
      expect {
        User3.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyer@veep.net"
      )
      }.to_not raise_error
    end
  end

  describe "when a user with a given first_name exists" do
    before { 
      User3.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyer@veep.net"
      )
    }

    it "creation of a new user with the same first name returns active record error" do
      expect {
        User3.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyers@veep.net"
      )
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: First name has already been taken")
    end
  end
end
