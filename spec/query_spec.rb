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
    Rake::Task["active_stash:create-collections"].invoke
  end

  after(:all) do
    User.collection.drop
    CreateUsers.migrate(:down)
  end

  before(:all) do
    ago_2 = 2.days.ago
    ago_5 = 5.days.ago

    User.create!([
      { first_name: "James", last_name: "Hetfield", gender: "M", dob: "Aug 3, 1963", created_at: 10.days.ago },
      { first_name: "Lars", last_name: "Ulrich", gender: "M", dob: "Dec 26, 1963", created_at: 10.days.ago },
      { first_name: "Kirk", last_name: "Hammett", gender: "M", dob: "Nov 18, 1962", created_at: 10.days.ago },
      { first_name: "Robert", last_name: "Trujillo", gender: "M", dob: "Oct 23, 1964", created_at: 10.days.ago },
      { first_name: "Melanie", last_name: "Brown", gender: "F", dob: "May 29, 1975", created_at: ago_5 },
      { first_name: "Emma", last_name: "Bunton", gender: "F", dob: "Jan 21, 1976", created_at: ago_5 },
      { first_name: "Melanie", last_name: "Chisholm", gender: "F", dob: "Jan 12, 1974", created_at: ago_2 },
      { first_name: "Geri", last_name: "Halliwell", gender: "F", dob: "Aug 6, 1972", created_at: ago_2 },
      { first_name: "Victoria", last_name: "Beckham", gender: "F", dob: "April 17, 1974", created_at: ago_2 }
    ])
  end

  # TODO
  # Add lockbox
  # Reduce the number of fields/indexes so tests run faster
  # first/last
  # Default scope
  # joins and includes tests

  describe "#query simple constraints" do
    it "by exact name (single, 1 result)" do
      expect(User.query(first_name: "James").first.first_name).to eq("James")
    end

    it "by exact gender (single, many results)" do
      expect(User.query(gender: "F").length).to eq(5)
    end

    it "by exact name, gender (conjunctive, many results)" do
      expect(User.query(first_name: "Melanie", gender: "F").length).to eq(2)
    end

    it "by exact name, gender limit=1 (conjunctive, 1 result)" do
      result = User.query(first_name: "Melanie", gender: "F").order(:dob).first
      expect(result.last_name).to eq("Chisholm")
    end
  end

  describe "#query block constraints" do
    it "by exact name (single)" do
      result = User.query { |q| q.first_name == "James" }.first
      expect(result.first_name).to eq("James")
    end

    it "by dob (all)" do
      results = User.query { |q| q.dob > "1970-01-01".to_date }
      expect(results.map(&:first_name)).to eq(%w(
        Melanie
        Emma
        Melanie
        Geri
        Victoria
      ))
    end

    it "by exact gender and dob (conjunctive, 1 result)" do
      results = User.query { |q|
        q.gender == "M"
        q.dob > "1963-12-01".to_date
      }.select(:first_name)

      expect(results.map(&:first_name)).to eq(%w(Lars Robert))
    end
  end

  describe "limit and offset" do
    it "by exact gender (limit=5)" do
      expect(User.query(gender: "F").limit(4).length).to eq(4)
    end

    it "limit=3,offset=7" do
      expect(User.limit(3).offset(7).length).to eq(2)
      expect(User.query.limit(3).offset(7).length).to eq(2)
    end

    it "limit=3,offset=4 with query" do
      expect(User.query(gender: "F").limit(3).offset(4).length).to eq(1)
    end
  end

  describe "order" do
    it "by one paramater asc (no constraints)" do
      results = User.order(:dob).map(&:first_name)
      expect(results).to eq(%w(
        Kirk
        James
        Lars
        Robert
        Geri
        Melanie
        Victoria
        Melanie
        Emma
      ))
    end

    it "by one paramater desc (with constraint)" do
      results = User.query(gender: "F").order(dob: :desc).map(&:first_name)
      expect(results).to eq(%w(
        Emma
        Melanie
        Victoria
        Melanie
        Geri
      ))
    end

    it "2 params asc (with constraint)" do
      results = User.query(gender: "F").order(:created_at, :dob).map(&:first_name)
      expect(results).to eq(%w(
        Melanie
        Emma
        Geri
        Melanie
        Victoria
      ))
    end

    it "2 params, 1 asc, 1 desc (with constraint)" do
      results = User.query(gender: "F").order(:created_at, dob: :desc).map(&:first_name)
      expect(results).to eq(%w(
        Emma
        Melanie
        Victoria
        Melanie
        Geri
      ))
    end
  end
end

