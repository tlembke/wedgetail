class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.column :name, :string
      t.column :agent_id, :integer
      t.column :timing, :integer
    end
  end

  def self.down
    drop_table :activities
  end
end
