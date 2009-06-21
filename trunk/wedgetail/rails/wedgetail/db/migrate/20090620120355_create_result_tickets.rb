class CreateResultTickets < ActiveRecord::Migration
  def self.up
    create_table :result_tickets do |t|
      t.string :result_ref
      t.string :ticket

      t.timestamps
    end
  end

  def self.down
    drop_table :result_tickets
  end
end
