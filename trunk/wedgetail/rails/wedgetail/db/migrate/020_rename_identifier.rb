class RenameIdentifier < ActiveRecord::Migration
  def self.up
    remove_index :patients, :identifier
    rename_column :patients, :identifier, :user_id
    add_index :patients, :user_id
  end

  def self.down
    remove_index :patients, :user_id
    rename_column :patients, :user_id, :identifier
    add_index :patients, :identifier
  end
end
