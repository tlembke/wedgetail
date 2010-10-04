class CreateCareroles < ActiveRecord::Migration
  def self.up
    create_table :careroles do |t|
      t.integer :craft_id,:default=>0
      t.integer :goal_id,:default=>0
      t.integer :patient_id,:default=>0
      t.text :role
      t.integer :root,:default=>0

      t.timestamps
    end
  end

  def self.down
    drop_table :careroles
  end
end
