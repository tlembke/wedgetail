class CreateCrafts < ActiveRecord::Migration
  def self.up
    create_table :crafts do |t|
      t.string :name
      t.integer :craftgroup_id

      t.timestamps
    end
  end

  def self.down
    drop_table :crafts
  end
end
