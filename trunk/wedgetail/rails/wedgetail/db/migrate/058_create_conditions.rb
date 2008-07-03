class CreateConditions < ActiveRecord::Migration
  def self.up
    create_table :conditions do |t|
      t.column :name, :string
      t.column :code, :string
    end
    Condition.create(:id=>'1',:name=>'Common')
  end

  def self.down
    drop_table :conditions
  end
end
