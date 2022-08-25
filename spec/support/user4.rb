class User4 < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users4"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users4"
  encrypts :first_name, :verified, :dob, :latitude
  stash_index :first_name, :verified, :dob, :latitude
end
