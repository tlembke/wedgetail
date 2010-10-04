class ChangeDefaultsGoals < ActiveRecord::Migration
  def self.up
    change_column :goals, :measure_id, :integer, :default=>0
    change_column :goals, :condition_id, :integer, :default=>0
    change_column :goals, :patient, :string, :default=>""
    change_column :goals, :team, :string, :default=>""
    change_column :goals, :active, :integer, :default=>1
  end

  def self.down
  end
end
