class User5 < ActiveRecord::Base
  # Used to test filter options on the match_all index
  include ActiveStash::Search
  include ActiveStash::Validations

  self.table_name = "users5"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users5"

  stash_match_all :first_name, :last_name, :email, filter_size: 512, filter_term_bits: 6
end
