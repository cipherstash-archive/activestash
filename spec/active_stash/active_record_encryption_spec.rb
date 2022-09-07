require 'spec_helper'
# TODO: mover t
# require 'rspec/expectations'

# ActiveRecord Encryption is only available from Rails 7.

if Rails::VERSION::MAJOR >= 7
  RSpec.describe "ActiveRecord Encryption" do
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
end
