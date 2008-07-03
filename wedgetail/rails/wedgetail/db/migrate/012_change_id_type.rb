class ChangeIdType < ActiveRecord::Migration
  def self.up
    change_column :narratives, :patient_identifier, :string, :null => false 
  end

  def self.down
    change_column :narratives, :patient_identifier, :integer
  end
end
