class Audit < ActiveRecord::Migration
  def self.up
    create_table :audits do |t| 
    t.column :patient_identifier, :integer 
    t.column :user_id, :integer 
    t.column :created_at,    :timestamp
    end 
    
  end
   
  def self.down
     drop_table :audits
  end
end
