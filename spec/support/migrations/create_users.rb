class CreateUsers < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :users do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :gender
      t.date :dob
      t.timestamps
      t.uuid :stash_id
    end
  end
end
