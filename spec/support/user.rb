class User < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"

  validates :email, uniqueness: true

  stash_index :first_name, :dob, :created_at, :email
  stash_index :gender, only: :exact
  stash_match_all :first_name, :last_name, :email
end
