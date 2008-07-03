class RenameNarr < ActiveRecord::Migration
  def self.up
      rename_column :narratives, :narrative_title, :title
      rename_column :narratives, :narrative_content, :content
  end 
  def self.down 
      rename_column :narratives, :title, :narrative_title
      rename_column :narratives, :content, :narrative_content
  end
end
