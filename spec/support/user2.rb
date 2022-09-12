class User2 < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users2"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users2"

  validates_uniqueness_of :email, case_sensitive: true

  stash_index do
    auto :first_name, :email, :dob, :last_name

    exact :gender, :title
    range :created_at, :updated_at

    match_all :first_name, :last_name, :email
  end
end
