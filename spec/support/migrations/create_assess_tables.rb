class CreateAssessTables < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :assess_users_no_encryption do |t|
      t.string :email
      t.timestamps
    end

    create_table :assess_users_active_record_encryption do |t|
      t.string :email
      t.timestamps
    end

    create_table :assess_users_lockbox do |t|
      t.string :email
      t.string :name_ciphertext
      t.timestamps
    end
  end
end
