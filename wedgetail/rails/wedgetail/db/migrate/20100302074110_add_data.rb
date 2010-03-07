class AddData < ActiveRecord::Migration
  def self.up
    add_column :narratives, :data, :binary, :limit => 1.megabyte
  end

  def self.down
    remove_column :narratives, :data
  end
end
