class CreateUsers4 < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :users4 do |t|
      t.string :first_name
      t.boolean :verified
      t.date :dob
      t.float :latitude
      t.timestamps
      t.uuid :stash_id
    end
  end
end
