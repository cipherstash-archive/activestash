require_relative "../support/user"
require_relative "../support/user_inconsistent"
require_relative "../support/migrations/create_users"

RSpec.describe "constistency checks" do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      username: 'dan',
      database: 'activestash_test'
    )

    CreateUsers.migrate(:up)
  end

  after(:all) do
    CreateUsers.migrate(:down)
  end

  before do
    User.collection.drop! rescue nil
  end

  after do
    User.collection.drop! rescue nil
  end

  describe "when no collection exists" do
    it "raises an error" do
      expect { User.collection.info }.to raise_error(ActiveStash::NoCollectionError)
    end
  end

  describe "when the backing collection exists" do
    before do
      User.collection.create!
    end

    it "does not raise an error" do
      expect { User.collection.info }.to_not raise_error
    end
  end

  describe "when the backing collection exists but is missing an index" do
    before do
      User.collection.create!
    end

    it "not raises an error" do
      expect { UserInconsistent.collection(true).info }.to raise_error(ActiveStash::CollectionDivergedError)
    end
  end
end
