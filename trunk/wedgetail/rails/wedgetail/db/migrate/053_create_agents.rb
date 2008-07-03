class CreateAgents < ActiveRecord::Migration
  def self.up
    create_table :agents do |t|
      t.column :role, :string
    end
    Agent.create(:id=>'1',:role=>'GP')
    Agent.create(:id=>'2',:role=>'CDM RN')
    Agent.create(:id=>'3',:role=>'CDM Admin')
    Agent.create(:id=>'4',:role=>'Patient')
    
  end

  def self.down
    drop_table :agents
  end
end
