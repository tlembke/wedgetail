class AddTeamToNarrative < ActiveRecord::Migration
  def self.up
    add_column :narratives, :created_team, :string
  end

  def self.down
    remove_column :narratives, :created_team
  end
end
