class ChangeActions < ActiveRecord::Migration
  def self.up
    rename_column :actions, :patient_ref, :wedgetail
    add_column :actions, :created_by, :string
  end

  def self.down
    rename_column :actions, :wedgetail, :patient_ref
    remove_column :actions, :created_by
  end
end
