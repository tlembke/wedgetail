class CreateMeasures < ActiveRecord::Migration
  def self.up
    create_table :measures do |t|
      t.string :name
      t.string :abbreviation
      t.text :description
      t.string :units
      t.decimal :target
      t.integer :operator

      t.timestamps
    end
  end

  def self.down
    drop_table :measures
  end
end
