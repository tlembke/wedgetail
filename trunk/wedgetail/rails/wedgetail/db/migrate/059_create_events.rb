class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :patient, :string
      t.column :month, :integer
      t.column :time, :time
      t.column :agent_id, :integer
      t.column :location, :string
      t.column :event_type_id, :integer
    end
  end

  def self.down
    drop_table :events
  end
end
