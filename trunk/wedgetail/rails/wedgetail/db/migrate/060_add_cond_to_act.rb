class AddCondToAct < ActiveRecord::Migration
  def self.up
    add_column :activities, :condition_id, :integer
  end

  def self.down
    remove_column :activities, :condition_id
  end
end
