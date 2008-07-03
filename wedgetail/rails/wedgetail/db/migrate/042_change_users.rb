class ChangeUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :crypto_pref, :integer, :default=>0
  end

  def self.down
    remove_column :users, :crypto_pref
  end
end