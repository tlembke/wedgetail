class CreateGoals < ActiveRecord::Migration
  def self.up
    create_table :goals do |t|
      t.string :title
      t.text :description
      t.integer :measure_id
      t.integer :condition_id
      t.string :patient
      t.string :team

      t.timestamps
    end
  end

  def self.down
    drop_table :goals
  end
end
