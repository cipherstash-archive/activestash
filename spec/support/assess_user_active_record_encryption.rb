class AssessUserActiveRecordEncryption < ActiveRecord::Base
  self.table_name = "assess_users_active_record_encryption"

  if Rails::VERSION::MAJOR >= 7
    encrypts :email
  end
end
