require_relative "support/user"
require_relative "support/migrations/create_users"
require 'rake'
load "tasks/active_stash.rake"

RSpec.describe ActiveStash::Search do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: 'localhost',
      username: 'dan',
      database: 'activestash_test'
    )

    CreateUsers.migrate(:up)

    schema = ActiveStash::SchemaBuilder.new(User).build
    client = CipherStash::Client.new(logger: ActiveStash::Logger.instance)
    client.create_collection(User.collection_name, schema)
  end

  after(:all) do
    User.collection.drop
    CreateUsers.migrate(:down)
  end

  describe "#cs_put" do
    let!(:user) do
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

