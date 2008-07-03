class ChangeItem < ActiveRecord::Migration
  def self.up
    change_column :claims, :item, :string
  end

  def self.down
    change_column :claims, :item, :integer
  end
end
