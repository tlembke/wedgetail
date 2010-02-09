class AddAction < ActiveRecord::Migration
  def self.up
    add_column :results, :action, :string
  end

  def self.down
    remove_column :results, :action
  end
end
