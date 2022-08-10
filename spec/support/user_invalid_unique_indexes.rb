class UserInvalidUniqueIndexes < ActiveRecord::Base
  include ActiveStash::Search
  self.table_name = "users2"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users2"

  stash_index :first_name, except: [:match, :range], unique: true
  stash_index :dob
  stash_index :gender, only: :exact
  stash_index :title, except: [:match, :range]
  stash_index :created_at, :updated_at, except: :range

  stash_index :email, unique: true

  # Invalid unique constraint on match
  stash_index :last_name, only: :match, unique: true

  stash_match_all :first_name, :email
end
