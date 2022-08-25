require_relative "../support/user4"
require_relative "../support/migrations/create_users4"

require 'rspec/expectations'

RSpec::Matchers.define :have_an_exact_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :exact }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_a_range_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :range }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_a_match_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :match }
    !target.nil? && target.name == name
  end
end

RSpec.describe ActiveStash::StashIndexes do
  before(:all) do
    CreateUsers4.migrate(:up)
  end

  after(:all) do
    CreateUsers4.migrate(:down)
  end

  let(:indexes) { User4.stash_indexes }

  describe "first_name" do
    subject { indexes.on(:first_name) }

    it "has 3 indexes defined" do
      expect(subject.length).to eq(3)
    end

    it { should have_an_exact_index("first_name") }
    it { should have_a_range_index("first_name_range") }
    it { should have_a_match_index("first_name_match") }
  end

  describe "boolean types" do
    subject { indexes.on(:verified) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_an_exact_index("verified") }
  end

  describe "date types" do
    subject { indexes.on(:dob) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_a_range_index("dob_range") }
  end

  describe "float types" do
    subject { indexes.on(:latitude) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_a_range_index("latitude_range") }
  end
end
