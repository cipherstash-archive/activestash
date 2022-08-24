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

  describe "validate_assoc_and_register_callback" do
    it "raises an error for a missing association" do
      expect {
        User.validate_assoc_and_register_callback(:nothing)
      }.to raise_error(/No such association/)
    end

    it "raises an error for an unsupported association type" do
      expect {
        User.validate_assoc_and_register_callback(:consultations)
      }.to raise_error(/Only 1-to-1 associations/)
    end

    it "does not raise when a valid association is provided" do
      expect {
        User.validate_assoc_and_register_callback(:patient)
      }.to_not raise_error
    end
  end
end
