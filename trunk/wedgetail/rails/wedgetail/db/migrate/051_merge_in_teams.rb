class MergeInTeams < ActiveRecord::Migration
  def self.up
    add_column :users, :team, :string
    Team.find(:all).each do |team|
      u = User.find_by_wedgetail(team.user_wedgetail,:order=>"created_at ASC")
      u.team = team.team_wedgetail
      u.save!
    end
    drop_table :teams
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end