class AddRoleIdToTeams < ActiveRecord::Migration
  def self.up
    add_column :teams, :craft_id, :integer, :default=>0
  end

  def self.down
    remove_column :teams, :craft_id
  end
end
