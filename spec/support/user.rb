class User < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"

  # Used for testing
  attr_accessor :skip_validations

  has_one :patient
  has_one :medicare_card

  validates_uniqueness_of :email, if: Proc.new { |user| user.perform_validations? }

  stash_index do
    auto :first_name, :dob, :created_at
    exact :gender, :email

    match_all :first_name, :last_name, :email

    index_assoc :patient do
      range :height, :weight
    end

    index_assoc :medicare_card do
      exact :medicare_number
      range :expiry_date
    end
  end

  def perform_validations?
    !self.skip_validations
  end
end
