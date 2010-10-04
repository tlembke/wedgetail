class AddActive < ActiveRecord::Migration
  def self.up
    add_column :goals, :active, :integer
  end

  def self.down
    remove_column :goals, :active
  end
end
