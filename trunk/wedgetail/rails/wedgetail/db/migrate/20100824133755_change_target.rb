class ChangeTarget < ActiveRecord::Migration
  def self.up
    rename_column :measures, :target, :value
  end

  def self.down
    rename_column :measures, :value, :target
  end
end
