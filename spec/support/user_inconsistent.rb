# This model is used to simulate an inconsistency when the client code defines
# an index that doesn't exist in CipherStash
class UserInconsistent < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_users"
  self.table_name = "users"

  stash_index :first_name, :dob, :created_at
  stash_index :gender, only: :exact
  stash_match_all :first_name, :last_name, :email

  # Adds
  stash_index :updated_at
end
