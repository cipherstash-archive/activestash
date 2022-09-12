class UserUniqueIndexes < ActiveRecord::Base
  include ActiveStash::Search
  self.table_name = "users2"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users2"

  stash_index do
    auto :last_name, :dob

    exact :email, :first_name, :gender, :title
    unique :email
    unique :first_name

    match :email

    range :created_at, :updated_at

    match_all :first_name, :email
  end

end
