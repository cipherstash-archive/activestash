class User < ActiveRecord::Base
  include ActiveStash::Search
  self.collection_name = "activestash_test_users"
end
