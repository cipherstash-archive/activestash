require_relative "support/user"
require_relative "support/migrations/create_users"

RSpec.describe "ActiveStash::Search.query" do
  before(:context) do
    User.delete_all
    User.collection.drop!
    User.collection.create!

    ago_2 = 2.days.ago
    ago_5 = 5.days.ago
    ago_10 = 10.days.ago

    User.create!([
      { first_name: "James", last_name: "Hetfield", gender: "M", dob: "Aug 3, 1963", created_at: ago_10, title: "Mr", email: "james@metalica.net" },
      { first_name: "Lars", last_name: "Ulrich", gender: "M", dob: "Dec 26, 1963", created_at: ago_10, title: "Mr", email: "lars@metalica.net" },
      { first_name: "Kirk", last_name: "Hammett", gender: "M", dob: "Nov 18, 1962", created_at: ago_10, title: "Mr", email: "kirk@metalica.net" },
      { first_name: "Robert", last_name: "Trujillo", gender: "M", dob: "Oct 23, 1964", created_at: ago_10, title: "Mr", email: "robert@metalica.net" },
      { first_name: "Melanie", last_name: "Brown", gender: "F", dob: "May 29, 1975", created_at: ago_5, title: "Ms", email: "scary@spicegirls.music" },
      { first_name: "Emma", last_name: "Bunton", gender: "F", dob: "Jan 21, 1976", created_at: ago_5, title: "Ms", email: "baby@spicegirls.music" },
      { first_name: "Melanie", last_name: "Chisholm", gender: "F", dob: "Jan 12, 1974", created_at: ago_2, title: "Ms", email: "sporty@spicegirls.music" },
      { first_name: "Geri", last_name: "Halliwell", gender: "F", dob: "Aug 6, 1972", created_at: ago_2, title: "Ms", email: "ginger@spicegirls.music" },
      { first_name: "Victoria", last_name: "Beckham", gender: "F", dob: "April 17, 1974", created_at: ago_2, title: "Ms", email: "posh@spicegirls.music" }
    ])
  end

  # TODO
  # Add lockbox
  # first/last
  # Default scope
  # joins and includes tests
  # match_multi index

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

    it "by range between" do
      results = User.query { |q|
        q.dob.between("1974-01-12".to_date, "1974-06-17".to_date)
      }.select(:first_name)

      expect(results.map(&:first_name)).to eq(%w(Melanie Victoria))
    end
  end

  describe "#query match" do
    it "raises error if trying to match a regex" do
      expect do
        User.query { |q| q.first_name =~ /Mel/ }
      end.to raise_error(ActiveStash::QueryError, /regular expressions/)
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

  describe "#select" do
    it "selects given fields when chained after query" do
      result = User.query(first_name: "Emma").select(:first_name, :last_name)
      expect(result[0].first_name).to eq("Emma")
      expect(result[0].last_name).to eq("Bunton")
      expect(result[0].id).to be_nil

      expect {
        result[0].dob
      }.to raise_error(ActiveModel::MissingAttributeError)
    end

    it "selects given fields when query is chained after select" do
      result = User.select(:first_name, :last_name).query(first_name: "Emma")
      expect(result[0].first_name).to eq("Emma")
      expect(result[0].last_name).to eq("Bunton")
      expect(result[0].id).to be_nil

      expect {
        result[0].dob
      }.to raise_error(ActiveModel::MissingAttributeError)
    end
  end

  describe "#stash_ids" do
    it "returns a list of record IDs when chained after query" do
      result = User.query(first_name: "Emma").stash_ids
      expect(result).to match([match(%r{\A\h{8}(-\h{4}){3}-\h{12}\z})])
    end
  end
end
