class CreateManagers < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :managers do |t|
      t.integer :options_granted

      t.references :employee, index: true, foreign_key: true, null: false

      t.uuid :stash_id

      t.timestamps
    end
  end
end
