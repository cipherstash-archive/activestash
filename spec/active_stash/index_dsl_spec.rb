require 'spec_helper'

class FakeUserModel
end


class FakeReflector
  def fields
    {
      "first_name" => :string,
      "description" => :text,
      "verified" => :boolean,
    }
  end

  def associations
    { }
  end
end

RSpec.describe ActiveStash::IndexDSL do

  describe "auto indexing" do
    it "should create exact, range and match indexes on string field" do
      dsl = ActiveStash::IndexDSL.new(FakeUserModel, [], FakeReflector.new)
      dsl.instance_eval do
        auto :first_name
      end

      config = dsl.finalize!

      expect(config.indexes.count_on("first_name")).to eq(3)

      expect(config.indexes.has?("first_name", :exact)).to be(true)
      expect(config.indexes.has?("first_name", :range)).to be(true)
      expect(config.indexes.has?("first_name", :match)).to be(true)
    end

    it "should create exact, range and match indexes on text field" do
      dsl = ActiveStash::IndexDSL.new(FakeUserModel, [], FakeReflector.new)
      dsl.instance_eval do
        auto :description
      end

      config = dsl.finalize!

      expect(config.indexes.count_on("description")).to eq(3)

      expect(config.indexes.has?("description", :exact)).to be(true)
      expect(config.indexes.has?("description", :range)).to be(true)
      expect(config.indexes.has?("description", :match)).to be(true)
    end

    it "should create range index on boolean" do
      dsl = ActiveStash::IndexDSL.new(FakeUserModel, [], FakeReflector.new)
      dsl.instance_eval do
        auto :verified
      end

      config = dsl.finalize!

      expect(config.indexes.count_on("verified")).to eq(1)

      expect(config.indexes.has?("verified", :range)).to be(true)
    end
  end

  describe "index_assoc" do
    before(:context) do
      User.collection.create!
      User.delete_all
    end

    after(:context) do
      User.delete_all
      User.collection.drop!
    end

    it "should index associated records" do
      user = create(:user, email: "person@example.net")
    end
  end

  describe ".finalize!" do
    it "multiple identical indexes on the same field raise an error" do
      dsl = ActiveStash::IndexDSL.new(FakeUserModel, [], FakeReflector.new)
      dsl.instance_eval do
        match :first_name
        match :first_name
      end

      expect{ dsl.finalize! }.to raise_error(
        ActiveStash::ConfigError,
        "Multiple indexes of the same type on the same attribute: FakeUserModel#first_name, index type: match"
      )
    end
  end

  # TODO test that executing match_all more than once fails
end