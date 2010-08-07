class AddViewed < ActiveRecord::Migration
  def self.up
    add_column :actions, :viewed, :integer, :default => 0
  end

  def self.down
    add_column :actions, :viewed
  end
end
