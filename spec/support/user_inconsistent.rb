# This model is used to simulate an inconsistency when the client code defines
# an index that doesn't exist in CipherStash
class UserInconsistent < User
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"
  self.table_name = "users"

  stash_index do
    # The addition of :updated_at is what wil trigger the inconsistency check
    auto :first_name, :email, :dob, :created_at, :updated_at
    exact :gender
    match_all :first_name, :last_name, :email
  end
end
