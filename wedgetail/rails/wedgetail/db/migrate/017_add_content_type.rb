class AddContentType < ActiveRecord::Migration
  def self.up
    add_column :narratives, :content_type, :string
  end

  def self.down
    remove_column :narratives, :content_type
  end
end
