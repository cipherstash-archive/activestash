class CreateConsultations < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :consultations do |t|
      t.string :notes
      t.timestamps
    end
  end
end
