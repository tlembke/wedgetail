class AddDefault < ActiveRecord::Migration
  def self.up
    add_column :teams, :default, :integer, :default => 0
  end

  def self.down
    remove_column :teams, :default
  end
end
