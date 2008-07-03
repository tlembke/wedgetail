class RenameItem < ActiveRecord::Migration
  def self.up
    rename_column :claims, :item, :item_number_id
  end

  def self.down
    rename_column :claims, :item_number_id, :item
  end
end
