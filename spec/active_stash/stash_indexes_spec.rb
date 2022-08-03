require_relative "../support/user2"
require_relative "../support/migrations/create_users2"

require_relative "../support/matchers"

RSpec.describe ActiveStash::StashIndexes do
  before(:all) do
    CreateUsers2.migrate(:up)
  end

  after(:all) do
    CreateUsers2.migrate(:down)
  end

  let(:indexes) { User2.stash_indexes }

  describe "first_name" do
    subject { indexes.on(:first_name) }

    it "has 3 indexes defined" do
      expect(subject.length).to eq(3)
    end

    it { should have_an_exact_index("first_name") }
    it { should have_a_range_index("first_name_range") }
    it { should have_a_match_index("first_name_match") }
  end

  describe "last_name" do
    subject { indexes.on(:last_name) }

    it "has 3 indexes defined" do
      expect(subject.length).to eq(3)
    end

    it { should have_an_exact_index("last_name") }
    it { should have_a_range_index("last_name_range") }
    it { should have_a_match_index("last_name_match") }
  end

  describe "dob" do
    subject { indexes.on(:dob) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_a_range_index("dob_range") }
  end

  describe "gender" do
    subject { indexes.on(:gender) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_an_exact_index("gender") }
  end

  describe "title" do
    subject { indexes.on(:title) }

    it "has 1 index defined" do
      expect(subject.length).to eq(1)
    end

    it { should have_an_exact_index("title") }
  end

  describe "multi match" do
    subject { indexes.get_match_multi }

    it "has a multi match defined for first and last name and email" do
      expect(subject.field).to eq([:first_name, :last_name, :email])
    end
  end
end
