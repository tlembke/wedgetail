class AddIdentifier < ActiveRecord::Migration
  def self.up
    add_column :results, :identifier, :string
  end

  def self.down
    remove_column :results, :identifier
  end
end
