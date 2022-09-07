class User < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"

  # Used for testing
  attr_accessor :skip_validations

  validates_uniqueness_of :email, if: Proc.new { |user| user.perform_validations? }

  stash_index do
    first_name :auto
    dob :auto
    created_at :auto
    gender :exact
  end

  stash_match_all :first_name, :last_name, :email

  def perform_validations?
    !self.skip_validations
  end
end
