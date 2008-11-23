class ModifyUser < ActiveRecord::Migration
  def self.up
    add_column :users, :created_by, :string
    add_column :users, :hatched, :boolean
  end

  def self.down
    remove_column :users, :created_by
    remove_column :users, :hatched
  end
  
end
