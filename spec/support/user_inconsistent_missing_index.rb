class UserInconsistentMissingIndex < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"
  self.table_name = "users"

  stash_index :first_name, :dob, :created_at
  stash_index :gender, only: :exact
  stash_match_all :first_name, :last_name, :email

  # Adds
  stash_index :updated_at
end
