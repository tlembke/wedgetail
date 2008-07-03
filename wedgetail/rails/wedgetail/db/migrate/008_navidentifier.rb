class Navidentifier < ActiveRecord::Migration
  def self.up
    rename_column :narratives, :patient_id, :patient_identifier
  end

  def self.down
    rename_column :narratives, :patient_identifier, :patient_id
  end
end
