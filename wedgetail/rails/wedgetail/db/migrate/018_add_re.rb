class AddRe < ActiveRecord::Migration
  def self.up
    add_column :messages, :re, :string
  end

  def self.down
    remove_column :messages, :re
  end
end
