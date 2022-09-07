class User2 < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users2"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users2"

  validates_uniqueness_of :email, case_sensitive: true

  stash_index do
    first_name :auto
    email :auto
    dob :auto
    last_name :auto

    gender :exact
    title :exact
    created_at :range
    updated_at :range
  end

  stash_match_all :first_name, :last_name, :email
end
