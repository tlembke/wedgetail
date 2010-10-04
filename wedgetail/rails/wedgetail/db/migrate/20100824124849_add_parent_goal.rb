class AddParentGoal < ActiveRecord::Migration
  def self.up
    add_column :goals, :parent, :integer, :default=>0
  end

  def self.down
    remove_column :goals, :parent
  end
end
