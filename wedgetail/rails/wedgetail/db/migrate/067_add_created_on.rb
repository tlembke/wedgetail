class AddCreatedOn < ActiveRecord::Migration
  def self.up
    add_column :claims, :created_at, :datetime
  end

  def self.down
    remove_column :claims, :created_at
  end
end
