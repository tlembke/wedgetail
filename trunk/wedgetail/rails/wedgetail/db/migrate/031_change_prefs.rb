class ChangePrefs < ActiveRecord::Migration
  def self.up
    change_column :prefs, :time_out, :integer, :default => 10
    change_column :prefs, :server_wedgetail, :string, :default => "0000"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
