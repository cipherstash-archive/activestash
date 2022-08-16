class CreateEmployees < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :employees do |t|
      t.integer :salary
      t.string :title
      t.date :started_on

      t.references :user, index: true, foreign_key: true, null: false

      t.uuid :stash_id

      t.timestamps
    end
  end
end
