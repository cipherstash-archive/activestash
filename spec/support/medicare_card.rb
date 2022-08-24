require_relative "./user"

class MedicareCard < ActiveRecord::Base
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_medicare_cards"

  belongs_to :user

  stash_index :medicare_number, only: :exact
  stash_index :expiry_date, only: :range
end
