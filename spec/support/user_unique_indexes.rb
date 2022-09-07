class UserUniqueIndexes < ActiveRecord::Base
  include ActiveStash::Search
  self.table_name = "users2"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users2"

  stash_index do
    email :exact, :unique
    email :match
    first_name :exact, :unique
    dob :auto
    last_name :auto
    gender :exact
    title :exact
    created_at :range
    updated_at :range
  end

  stash_match_all :first_name, :email
end
