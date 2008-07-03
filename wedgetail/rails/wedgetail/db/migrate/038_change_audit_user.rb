class ChangeAuditUser < ActiveRecord::Migration
  def self.up
    rename_column :audits, :user, :user_wedgetail
  end

  def self.down
    rename_column :audits, :user_wedgetail, :user
  end
end
