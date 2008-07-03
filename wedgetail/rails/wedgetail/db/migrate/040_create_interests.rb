class CreateInterests < ActiveRecord::Migration
  def self.up
    create_table :interests,:id=>false do |t|
      t.column :patient,    :string
      t.column :user,    :string
    end
  end

  def self.down
    drop_table :interests
  end
end
