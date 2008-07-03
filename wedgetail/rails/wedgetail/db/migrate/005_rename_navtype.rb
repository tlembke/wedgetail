class RenameNavtype < ActiveRecord::Migration
  def self.up 
    rename_column :narratives, :narrative_type, :narrative_type_id
  end 
  def self.down 
    rename_column :narratives, :narrative_type_id, :narrative_type
  end 

end
