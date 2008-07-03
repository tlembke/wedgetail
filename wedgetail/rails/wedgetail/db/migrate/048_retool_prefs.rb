class RetoolPrefs < ActiveRecord::Migration
  def self.up
    Pref.delete_all
    remove_column :prefs,:server_wedgetail
    remove_column :prefs,:use_ssl
    remove_column :prefs,:time_out
    add_column :prefs,:name,:string
    add_column :prefs,:value,:string
  end

  def self.down
    Pref.delete_all
    remove_column :prefs,:name
    remove_column :prefs,:value
    add_column :prefs,:server_wedgetail,:string,:default=>'0000'
    add_column :prefs,:time_out,:integer,:default=>10
    add_column :prefs,:use_ssl,:integer
    Pref.create(:id=>'1',:server_wedgetail=>'000',:time_out=>10,:use_ssl=>0)
  end
end
