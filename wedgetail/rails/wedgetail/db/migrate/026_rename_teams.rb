class RenameTeams < ActiveRecord::Migration
  def self.up
    rename_column :teams, :team, :team_wedgetail
    rename_column :teams, :wedgetail, :user_wedgetail
  end

  def self.down
    rename_column :teams,  :team_wedgetail, :team
    rename_column :teams, :user_wedgetail, :wedgetail
  end
end
