class MedicareCard < ActiveRecord::Base
  include ActiveStash::Search
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_medicare_cards"

  belongs_to :user

  stash_index do
    exact :medicare_number
    range :expiry_date
  end
end
