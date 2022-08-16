class Manager < ActiveRecord::Base
  include ActiveStash::Search
  self.table_name = "managers"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_managers"

  # I mean, I guess so?  AR doesn't have an "is_a" association type, after all.
  belongs_to :employee

  stash_index :options_granted
  stash_index employee: %i{title salary started_on}
  stash_index employee: { user: %i{first_name last_name dob} }
end
