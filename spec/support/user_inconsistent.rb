# This model is used to simulate an inconsistency when the client code defines
# an index that doesn't exist in CipherStash
class UserInconsistent < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"
  self.table_name = "users"

  stash_index do
    first_name :auto
    email :auto
    dob :auto
    created_at :auto
    updated_at :auto # This is the addition that will trigger the inconsistency check
    gender :exact
  end

  stash_match_all :first_name, :last_name, :email
end
