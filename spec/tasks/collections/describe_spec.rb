require "spec_helper"
require "rake"

RSpec.describe "active_stash:collections:describe" do
  before do
    Rake.application.rake_require "tasks/active_stash"
    Rake::Task.define_task(:environment)

    User.collection.create!
  end

  after do
    User.collection.drop!
  end

  it "succeeds given a model that uses ActiveStash::Search" do
    expected_output = <<~STR
    +---------------------------------+-------+------------------------------+---------------------------+
    | Name                            | Type  | Field(s)                     | Valid Operators           |
    +---------------------------------+-------+------------------------------+---------------------------+
    | first_name_range                | range | first_name                   | <, <=, >, >=, ==, between |
    | first_name                      | exact | first_name                   | ==                        |
    | first_name_match                | match | first_name                   | =~                        |
    | dob_range                       | range | dob                          | <, <=, >, >=, ==, between |
    | created_at_range                | range | created_at                   | <, <=, >, >=, ==, between |
    | gender                          | exact | gender                       | ==                        |
    | email                           | exact | email                        | ==                        |
    | __match_multi                   | match | first_name, last_name, email | =~                        |
    | patient.height_range            | range | height                       | <, <=, >, >=, ==, between |
    | patient.weight_range            | range | weight                       | <, <=, >, >=, ==, between |
    | medicare_card.medicare_number   | exact | medicare_number              | ==                        |
    | medicare_card.expiry_date_range | range | expiry_date                  | <, <=, >, >=, ==, between |
    +---------------------------------+-------+------------------------------+---------------------------+
    STR

    expect do
      Rake.application.invoke_task("active_stash:collections:describe[User]")
    end.to output(expected_output).to_stdout
  end
end
