require_relative "./patient"
require_relative "./consultation"
require_relative "./medicare_card"

class User < ActiveRecord::Base
  include ActiveStash::Search
  include ActiveStash::Validations
  self.table_name = "users"
  self.collection_name = "activestash_test_#{ENV["ACTIVE_STASH_TEST_COLLECTION_PREFIX"] || ""}_users"

  # Used for testing
  attr_accessor :skip_validations

  validates_uniqueness_of :email, if: Proc.new { |user| user.perform_validations? }

  stash_index :first_name, :dob, :email, :created_at, :updated_at

  has_one :patient
  has_one :medicare_card
  has_many :consultations

  stash_index :first_name, :dob, :email, :created_at, :updated_at
  stash_index :gender, only: :exact
  stash_index patient: [:height, :weight]
  stash_index medicare_card: [:medicare_number, :expiry_date]

  def perform_validations?
    !self.skip_validations
  end
end
