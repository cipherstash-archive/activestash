# This model is used to simulate an inconsistency when the client code
# does not define all the indexes that exist in CipherStash
class UserInconsistent2 < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_users"
  self.table_name = "users"

  stash_index :first_name, :dob, :created_at
end
