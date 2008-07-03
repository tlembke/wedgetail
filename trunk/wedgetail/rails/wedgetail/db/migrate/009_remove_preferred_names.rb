class RemovePreferredNames < ActiveRecord::Migration
  def self.up
    remove_column  :patients,  :preferred_name
  end

  def self.down
    add_column :patients, :preferred_name, :boolean, :default => 1
  end
end
