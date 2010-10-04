class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.string :patient
      t.string :member
      t.integer :confirmed,:default=>0
      t.string :name
      t.string :role
      t.timestamps
    end
    
  end

  def self.down
    drop_table :teams
  end
end
