require_relative "support/user"
require_relative "support/migrations/create_users"
require 'rake'
load "tasks/active_stash.rake"

RSpec.describe ActiveStash::Search do
  describe "#cs_put" do
    before(:example) do
      User.collection.create!
    end

    after(:example) do
      User.collection.drop!
    end

    let(:user) do
      User.create!(
        first_name: "James",
        last_name: "Hetfield",
        gender: "M",
        dob: "Aug 3, 1963",
        created_at: 10.days.ago,
        title: "Mr",
        email: "james@metalica.net"
      )
    end

    it "should have stash_id set" do
      expect(user.stash_id).not_to be_nil
    end

    it "should set stash_id when indexing an existing record" do
      user.update_column(:stash_id, nil)
      expect(user.stash_id).to be_nil
      user.cs_put
      expect(user.stash_id).not_to be_nil
    end
  end
end

