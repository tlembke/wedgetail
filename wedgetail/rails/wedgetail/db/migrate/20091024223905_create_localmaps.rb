class CreateLocalmaps < ActiveRecord::Migration
  def self.up
    create_table :localmaps do |t|
      t.string :team
      t.string :localID
      t.string :wedgetail

      t.timestamps
    end
  end

  def self.down
    drop_table :localmaps
  end
end
