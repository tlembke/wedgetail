class AddAccess < ActiveRecord::Migration
  def self.up
    add_column :users, :access, :integer
  end

  def self.down
    remove_column  :users,  :access
  end
end
