class AddCode < ActiveRecord::Migration
  def self.up
    add_column :claims, :code, :string
  end

  def self.down
    remove_column :claims, :code
  end
end
