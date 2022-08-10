require_relative "support/user"
require_relative "support/user_unique_indexes"
require_relative "support/migrations/create_users"
require_relative "support/migrations/create_users2"

RSpec.describe "ActiveStash::Search.cs_put" do
  describe "#cs_put" do
    before(:example) do
      User.collection.create!
      User.delete_all
    end

    after(:example) do
      User.delete_all
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
        email: "james@metallica.net"
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

  describe "#cs_put with unique cs indexes with a unique constraint on email" do
    before(:all) do
      CreateUsers2.migrate(:up)
    end

    after(:all) do
      CreateUsers2.migrate(:down)
    end

    before(:each) do
      UserUniqueIndexes.collection.create!
    end

    after(:each) do
      UserUniqueIndexes.delete_all
      UserUniqueIndexes.collection.drop!
    end

    it "should raise an error on insert of duplicate" do
      UserUniqueIndexes.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyer@veep.net"
      )

      expect do
        UserUniqueIndexes.create!(
          first_name: "Serena",
          last_name: "Meyer",
          gender: "F",
          dob: "Jan 1, 1962",
          created_at: 10.days.ago,
          title: "Ms",
          email: "smeyer@veep.net"
        )
      end.to raise_error(CipherStash::Client::Error::RecordPutFailure)
    end

    it "an error will be raised if the email is in a different case" do
      UserUniqueIndexes.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyer@veep.net"
      )

      expect do
        UserUniqueIndexes.create!(
          first_name: "Serena",
          last_name: "Meyer",
          gender: "F",
          dob: "Jan 1, 1962",
          created_at: 10.days.ago,
          title: "Ms",
          email: "SMEyer@Veep.net"
        )
      end.to raise_error(CipherStash::Client::Error::RecordPutFailure)
    end

    it "does not raise an error if the email is not a duplicate" do
       UserUniqueIndexes.create!(
        first_name: "Selina",
        last_name: "Meyer",
        gender: "F",
        dob: "Jan 1, 1961",
        created_at: 10.days.ago,
        title: "Ms",
        email: "smeyer@veep.net"
      )

      expect do
        UserUniqueIndexes.create!(
          first_name: "Serena",
          last_name: "Meyer",
          gender: "F",
          dob: "Jan 1, 1962",
          created_at: 10.days.ago,
          title: "Ms",
          email: "smeyers@veep.net"
        )
      end.not_to raise_error()
    end
  end
end
