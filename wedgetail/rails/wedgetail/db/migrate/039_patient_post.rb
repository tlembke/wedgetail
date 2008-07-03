class PatientPost < ActiveRecord::Migration
  def self.up
     add_column :users, :patient_post, :integer, :default => 0
  end

  def self.down
     remove_column :users, :patient_post
  end
end
