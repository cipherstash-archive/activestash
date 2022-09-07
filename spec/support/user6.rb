class User6 < ActiveRecord::Base
  # Used to test filter options on a specific index
  include ActiveStash::Search

  self.table_name = "users6"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users6"

  stash_index do
    first_name :auto
    last_name :auto
    email :match, filter_size: 512, filter_term_bits: 6
  end
end
