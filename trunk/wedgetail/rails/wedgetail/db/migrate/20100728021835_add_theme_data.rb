class AddThemeData < ActiveRecord::Migration
  def self.up
    Theme.delete_all
    Theme.create(:id=>'1',:name=>'Original',:css=>"wedgetail",:button=>0)
    Theme.create(:id=>'2',:name=>'Turquoise-orange',:css=>"wedgetail-turquoise-orange",:button=>1)
    Theme.create(:id=>'3',:name=>'Silver-blue',:css=>"wedgetail-silver-blue",:button=>1)
   end

  def self.down
    Theme.delete_all
  end
end
