require_relative "../support/user"

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
  end
end
