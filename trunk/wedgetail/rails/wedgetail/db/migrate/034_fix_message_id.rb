class FixMessageId < ActiveRecord::Migration
  def self.up
     change_column :messages, :recipient_id, :string
     change_column :messages, :sender_id, :string
   end
   def self.down
     change_column :messages, :recipient_id, :integer
     change_column :messages, :sender_id, :integer
   end
end
