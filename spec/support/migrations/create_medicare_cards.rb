class CreateMedicareCards < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :medicare_cards do |t|
      t.string :medicare_number
      t.date :expiry_date
      t.string :stash_id
      t.references :user
    end
  end
end
