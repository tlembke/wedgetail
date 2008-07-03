class RenameDefault < ActiveRecord::Migration
  def self.up
    remove_column :teams, :default
    add_column :teams, :default_flag, :integer, :default => 0
  end

  def self.down
    add_column :teams, :default, :integer, :default => 0
    remove_column :teams, :default_flag
  end
end
