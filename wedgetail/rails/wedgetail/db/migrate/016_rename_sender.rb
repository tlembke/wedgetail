class RenameSender < ActiveRecord::Migration
  def self.up
    rename_column :messages, :sender, :sender_id
    rename_column :messages, :recipient, :recipient_id
  end

  def self.down
    rename_column :messages, :sender_id, :sender
    rename_column :messages, :recipient_id, :recipeint
  end
end
