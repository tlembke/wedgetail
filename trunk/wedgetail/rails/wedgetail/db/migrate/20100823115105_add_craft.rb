class AddCraft < ActiveRecord::Migration
  def self.up
    add_column :users, :craft_id, :integer
  end

  def self.down
    remove_column :users, :craft_id
  end
end
