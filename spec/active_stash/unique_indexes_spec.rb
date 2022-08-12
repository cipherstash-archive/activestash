require_relative "../support/user_unique_indexes"
require_relative "../support/user_invalid_unique_indexes"
require_relative "../support/migrations/create_users2"

require 'rspec/expectations'

RSpec::Matchers.define :have_an_exact_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :exact }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_an_exact_unique_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :exact}
    !target.nil? && target.name == name && target.unique == true
  end
end

RSpec::Matchers.define :have_a_range_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :range }
    !target.nil? && target.name == name
  end
end

RSpec::Matchers.define :have_a_range_unique_index do |name|
  match do |actual|
    target = actual.find { |i| i.type == :range }
    !target.nil? && target.name == name  && target.unique == true
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
    CreateUsers2.migrate(:up)
  end

  after(:all) do
    CreateUsers2.migrate(:down)
  end

  let(:indexes) { UserUniqueIndexes.stash_indexes }

  describe "first_name with unique exact" do
    subject { indexes.on(:first_name) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_an_exact_unique_index("first_name") }
  end

  describe "email with a match and a unique constraint on range and exact" do
    subject { indexes.on(:email)}

    it "has 3 indexes defined" do
      expect(subject.length).to eq(3)
    end

    it { should have_an_exact_unique_index("email") }
    it { should have_a_range_unique_index("email_range") }
    it { should have_a_match_index("email_match") }
  end

  describe "last_name without a unique constraint specified" do
    subject { indexes.on(:last_name)}

    it "has 3 indexes defined" do
      expect(subject.length).to eq(3)
    end

    it { should have_an_exact_index("last_name") }
    it { should have_a_range_index("last_name_range") }
    it { should have_a_match_index("last_name_match") }
  end

  describe "invalid unique constraints" do
    it "unique on a match field should raise a config error" do
        expect { UserInvalidUniqueIndexes.stash_indexes }.to raise_error(ActiveStash::ConfigError)
    end
  end
end
