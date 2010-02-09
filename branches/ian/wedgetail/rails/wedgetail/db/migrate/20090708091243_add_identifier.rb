class AddIdentifier < ActiveRecord::Migration
  def self.up
    add_column :actions, :identifier, :string
  end

  def self.down
    remove_column :actions, :identifier
  end
end
