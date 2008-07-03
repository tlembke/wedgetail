class CreateOutgoingMessages < ActiveRecord::Migration
  def self.up
    create_table :outgoing_messages do |t|
      t.column :acktype,:string
      t.column :ack,:text
      t.column :acked_at,:datetime
      t.column :narrative_id,:integer
      t.column :status,:integer,:default=>0 # 1=sent once, 2=sent twice, .... 100=never got ack, 200=got ack, 300=don't expect ACK
      t.column :recipient_id,:string
      t.column :last_sent,:datetime
    end
    add_column :narratives, :plaintext,:text
    add_column :narratives, :awaiting_pickup,:boolean,:default=>false
    add_column :narratives, :hl7_id, :string
    add_column :narratives, :hl7_reply_id, :string
    add_column :patients, :medicare, :string
  end

  def self.down
    drop_table :outgoing_messages
    remove_column :narratives,:plaintext
    remove_column :narratives, :awaiting_pickup
    remove_column :narratives, :hl7_id
    remove_column :narratives, :hl7_reply_id
    remove_column :patients, :medicare
  end
end
