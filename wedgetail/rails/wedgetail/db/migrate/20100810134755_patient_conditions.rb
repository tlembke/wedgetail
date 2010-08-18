class PatientConditions < ActiveRecord::Migration
  def self.up
    create_table :patients_conditions, :id => false do |t|
       t.string :wedgetail 
       t.integer :condition_id
    end
  end

  def self.down
    drop_table :patients_conditions
  end
end
