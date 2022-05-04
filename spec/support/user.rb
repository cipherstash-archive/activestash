class User < ActiveRecord::Base
  include ActiveStash::Search
  self.collection_name = "activestash_test_users"

  stash_index :first_name, :dob, :created_at
  stash_index :gender, only: :exact
end
