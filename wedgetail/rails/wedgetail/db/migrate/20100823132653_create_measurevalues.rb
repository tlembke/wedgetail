class CreateMeasurevalues < ActiveRecord::Migration
  def self.up
    create_table :measurevalues do |t|
      t.string :patient
      t.integer :measure_id
      t.integer :value
      t.date :value_date
      t.string :created_by

      t.timestamps
    end
  end

  def self.down
    drop_table :measurevalues
  end
end
