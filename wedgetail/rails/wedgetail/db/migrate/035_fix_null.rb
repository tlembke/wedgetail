class FixNull < ActiveRecord::Migration
  def self.up
     change_column :users, :family_name, :string, :null=>false
     change_column :users, :given_names, :string, :null=>false
   end
   def self.down
     change_column :users, :family_name, :string, :null=>true
     change_column :users, :given_names, :string, :null=>true
   end
end
