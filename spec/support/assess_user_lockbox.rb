require "lockbox"

class AssessUserLockbox < ActiveRecord::Base
  self.table_name = "assess_users_lockbox"

  # non-default column name
  has_encrypted :encrypted_email, encrypted_attribute: :email

  # default column name (name_ciphertext)
  has_encrypted :name
end
