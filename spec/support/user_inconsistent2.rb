# This model is used to simulate an inconsistency when the client code
# does not define all the indexes that exist in CipherStash
class UserInconsistent2 < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"
  self.table_name = "users"

  stash_index do
    first_name :auto
    dob :auto
    created_at :auto
  end
end
