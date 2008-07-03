class CreateConsultations < ActiveRecord::Migration
  def self.up
    create_table :consultations do |t|
      t.column :code, :string
      t.column :condition_id, :integer
      t.column :month, :integer
    end
  end

  def self.down
    drop_table :consultations
  end
end
