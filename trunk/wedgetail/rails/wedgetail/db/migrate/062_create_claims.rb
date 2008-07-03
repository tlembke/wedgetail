class CreateClaims < ActiveRecord::Migration
  def self.up
    create_table :claims do |t|
       t.column :wedgetail, :string
       t.column :item, :integer
       t.column :date, :date
    end
  end

  def self.down
    drop_table :claims
  end
end
