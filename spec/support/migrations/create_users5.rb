class CreateUsers5 < ActiveRecord::Migration[(ENV["RAILS_VERSION"] || "7.0").to_f]
  def change
    create_table :users5 do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
    end
  end
end
