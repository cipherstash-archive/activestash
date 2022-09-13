require 'spec_helper'

RSpec.describe "Unique indexes" do
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

    it "has 1 index defined" do
      expect(subject.length).to eq(2)
    end

    it { should have_an_exact_unique_index("email") }
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
end
