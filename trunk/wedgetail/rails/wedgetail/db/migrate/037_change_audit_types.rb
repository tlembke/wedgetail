class ChangeAuditTypes < ActiveRecord::Migration
  def self.up
    rename_column :audits, :wedgetail, :patient
    change_column :audits, :patient, :string
    rename_column :audits, :user_id, :user
    change_column :audits, :user, :string
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
