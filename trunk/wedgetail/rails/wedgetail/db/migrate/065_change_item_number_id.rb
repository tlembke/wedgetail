class ChangeItemNumberId < ActiveRecord::Migration
  def self.up
    change_column :claims, :item_number_id, :integer
  end

  def self.down
    change_column :claims, :item_number_id, :string
  end
end
