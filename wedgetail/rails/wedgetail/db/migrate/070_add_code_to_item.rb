class AddCodeToItem < ActiveRecord::Migration
  def self.up
    add_column :item_numbers, :code, :string
  end

  def self.down
    remove_column :item_numbers, :code
  end
end
