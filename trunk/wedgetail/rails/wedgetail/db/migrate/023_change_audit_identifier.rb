class ChangeAuditIdentifier < ActiveRecord::Migration
  def self.up
     rename_column :audits, :patient_identifier, :wedgetail
  end

  def self.down
    rename_column :audits, :wedgetail, :patient_identifier
  end
end
