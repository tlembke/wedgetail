class AddPrefData < ActiveRecord::Migration
  def self.up
    Pref.delete_all
    Pref.create(:id=>'1',:server_wedgetail=>'000',:time_out=>10,:use_ssl=>0)
  end

  def self.down
    Pref.delete_all
  end
end
