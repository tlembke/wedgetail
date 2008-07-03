class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :sender,     :integer
      t.column :recipient,  :integer
      t.column :subject,    :string
      t.column :content,    :text
      t.column :created_at, :timestamp
      t.column :thread,     :integer
      t.column :status,     :integer
    end
  end

  def self.down
    drop_table :messages
  end
end
