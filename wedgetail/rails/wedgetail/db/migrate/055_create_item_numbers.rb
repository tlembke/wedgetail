class CreateItemNumbers < ActiveRecord::Migration
  def self.up
    create_table :item_numbers do |t|
      t.column :number, :integer
      t.column :name, :string
      t.column :description, :string
    end
  end

  def self.down
    drop_table :item_numbers
  end
end
