class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.column:team,    :string
      t.column:wedgetail, :string
    end
  end

  def self.down
      drop_table :teams
  end
end
