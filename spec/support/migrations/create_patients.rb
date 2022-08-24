class CreatePatients < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :patients do |t|
      t.float :height
      t.float :weight
      t.references :user
      t.timestamps
    end
  end
end
