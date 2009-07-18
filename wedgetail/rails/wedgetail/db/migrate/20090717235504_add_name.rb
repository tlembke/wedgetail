class AddName < ActiveRecord::Migration
  def self.up
    add_column :actions, :name, :string
  end

  def self.down
    remove_column :actions, :name
  end
end
