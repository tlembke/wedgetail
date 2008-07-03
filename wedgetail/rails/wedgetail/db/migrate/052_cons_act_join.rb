class ConsActJoin < ActiveRecord::Migration
  def self.up
    create_table :activities_consultations, :id => false do |t|
      t.column :activity_id, :integer
      t.column :consultation_id, :integer
    end
  
  end

  def self.down
    drop_table :activities_consultations
  end
  
  
end
