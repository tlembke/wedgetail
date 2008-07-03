class ChangeServerId < ActiveRecord::Migration
  def self.up
    rename_column :prefs, :server_id, :server_wedgetail
  end

  def self.down
    rename_column :prefs,  :server_wedgetail, :server_id
  end
end
