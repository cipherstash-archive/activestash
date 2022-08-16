class Employee < ActiveRecord::Base
  include ActiveStash::Search
  self.table_name = "employees"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_employees"

  belongs_to :user

  stash_index :started_on, :salary
  stash_index user: %i{first_name last_name dob}
end
