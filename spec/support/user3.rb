class User3 < ActiveRecord::Base
#   Example model where the field (:first_name) has not been indexed
#   into CipherStash and uniqueness validations are added.
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users3"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users3"

  # Used for testing
  attr_accessor :skip_validations

  validates_uniqueness_of :email, :first_name, if: Proc.new { |user| user.perform_validations? }

  stash_index do
    auto :dob, :created_at, :email
    exact :gender
    match_all :last_name, :email
  end


  def perform_validations?
    !self.skip_validations
  end
end
