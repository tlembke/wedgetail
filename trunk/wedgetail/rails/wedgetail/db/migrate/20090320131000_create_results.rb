class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.string :wedgetail
      t.string :surname
      t.string :given_name
      t.date :dob
      t.date :date
      t.string :name
      t.string :loinc
      t.string :value
      t.string :lab_text

      t.timestamps
    end
  end

  def self.down
    drop_table :results
  end
end
