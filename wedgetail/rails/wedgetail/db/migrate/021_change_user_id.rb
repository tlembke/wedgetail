class ChangeUserId < ActiveRecord::Migration
  def self.up
    remove_index :patients, :user_id
    rename_column :patients, :user_id, :wedgetail
    add_index :patients, :wedgetail
  end

  def self.down
    remove_index :patients, :wedgetail
    rename_column :patients, :wedgetail, :user_id
    add_index :patients, :user_id
  end
end
