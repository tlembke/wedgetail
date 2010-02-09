class AddAck < ActiveRecord::Migration
  def self.up
    add_column :results, :ack, :datetime
  end

  def self.down
    remove_column :results, :ack
  end
end
