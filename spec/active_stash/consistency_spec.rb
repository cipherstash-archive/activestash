require_relative "../support/user"
require_relative "../support/user_inconsistent_missing_index"
require_relative "../support/user_inconsistent_extra_index"

RSpec.describe "consistency checks" do
  describe "when no collection exists" do
    before(:each) do
      User.collection.drop!
    end

    after(:each) do
      User.collection.create!
    end

    it "raises an error" do
      expect { User.collection.info }.to raise_error(ActiveStash::NoCollectionError)
    end
  end

  describe "when the backing collection exists" do
    it "does not raise an error" do
      expect { User.collection.info }.to_not raise_error
    end

    describe "but is missing an index" do
      it "raises an error" do
        expect { UserInconsistentMissingIndex.collection(true).info }.to raise_error(ActiveStash::CollectionDivergedError)
      end
    end

    describe "but has an additional index" do
      it "raises an error" do
        expect { UserInconsistentExtraIndex.collection(true).info }.to raise_error(ActiveStash::CollectionDivergedError)
      end
    end
  end
end
