require_relative "../support/user"
require_relative "../support/employee"
require_relative "../support/manager"

require_relative "../support/matchers"

RSpec.describe ActiveStash::StashIndexes do
  describe User do
    let(:indexes) { User.stash_indexes }

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

  describe Employee do
    let(:indexes) { described_class.stash_indexes }

    describe "user.first_name" do
      subject { indexes.on(user: :first_name) }

      it "has all the good indexes defined" do
        expect(subject.length).to eq(3)
      end

      it { should have_an_exact_index("user__first_name") }
      it { should have_a_range_index("user__first_name_range") }
      it { should have_a_match_index("user__first_name_match") }
    end
  end

  describe Manager do
    let(:indexes) { described_class.stash_indexes }

    describe "user.employee.first_name" do
      subject { indexes.on(employee: { user: :first_name }) }

      it "has all the good indexes defined" do
        expect(subject.length).to eq(3)
      end

      it { should have_an_exact_index("employee__user__first_name") }
      it { should have_a_range_index("employee__user__first_name_range") }
      it { should have_a_match_index("employee__user__first_name_match") }
    end

    describe "employee.salary" do
      subject { indexes.on(employee: :salary) }

      it "has all the good indexes defined" do
        expect(subject.length).to eq(1)
      end

      it { should have_a_range_index("employee__salary_range") }
    end
  end

  describe "error conditions" do
    it "explodes if we try to pass an array of field names" do
      k = Class.new(ActiveRecord::Base)
      k.include(ActiveStash::Search)

      expect do
        k.stash_index %i{foo bar baz}
      end.to raise_error(ArgumentError)
    end
  end
end
