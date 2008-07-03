class Prefname < ActiveRecord::Migration
  def self.up
    add_column :patients, :preferred_name, :boolean, :default => 1
    add_column :patients, :visibility, :boolean, :default =>1
  end

  def self.down
    remove_column  :patients,  :preferred_name
    remove_column  :patients,  :visibilty
  end
end
