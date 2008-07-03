class CreateEventTypes < ActiveRecord::Migration
  def self.up
    create_table :event_types do |t|
      t.column :name, :string
    end
    EventType.create(:id=>'1',:name=>'GP Appointment')
    EventType.create(:id=>'2',:name=>'CDM Appointment')
    EventType.create(:id=>'3',:name=>'Allied Health Appointment')
    EventType.create(:id=>'4',:name=>'Specialist Appointment')
    EventType.create(:id=>'5',:name=>'Pathology')
    EventType.create(:id=>'6',:name=>'Radiology')
    EventType.create(:id=>'7',:name=>'Activity')
    
    
  end

  def self.down
    drop_table :event_types
  end
end
