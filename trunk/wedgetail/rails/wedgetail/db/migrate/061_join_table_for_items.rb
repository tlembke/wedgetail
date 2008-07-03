class JoinTableForItems < ActiveRecord::Migration
  def self.up
    create_table :consultations_item_numbers, :id => false do |t|
      t.column :consultation_id, :integer
      t.column :item_number_id, :integer
    end
  end

  def self.down
    drop_table :consultations_item_numbers
  end
end
