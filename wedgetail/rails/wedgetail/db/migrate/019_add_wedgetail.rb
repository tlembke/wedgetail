class AddWedgetail < ActiveRecord::Migration
  def self.up
    add_column :users, :wedgetail, :string
  end

  def self.down
    remove_column :users, :wedgetail
  end
end
