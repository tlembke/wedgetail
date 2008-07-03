class ChangeIdentifierToWedgetail < ActiveRecord::Migration
  def self.up
    rename_column :narratives, :patient_identifier, :wedgetail
  end

  def self.down
    rename_column :narratives, :wedgetail, :patient_identifier
  end
end
