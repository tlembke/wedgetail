class CreateCodes < ActiveRecord::Migration
  def self.up
    create_table :codes do |t|
      t.column :code, :string
      t.column :name, :string
      t.column :values, :text
      t.column :type, :string
      t.column :deleted, :boolean, :default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :codes
  end
end
