class ChangeValueInMeasures < ActiveRecord::Migration
  def self.up
    change_column :goals, :measure_id, :integer, :default=>0, :null=>false
    change_column :goals, :condition_id, :integer, :default=>0, :null=>false
    change_column :measures, :value, :decimal, :precision => 8, :scale => 2
    change_column :measurevalues, :value, :decimal, :precision => 8, :scale => 2
    add_column :measures, :places, :integer, :default=>0, :null=>false
  end

  def self.down
  end
end
