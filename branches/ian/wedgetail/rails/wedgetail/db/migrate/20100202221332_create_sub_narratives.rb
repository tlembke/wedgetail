class CreateSubNarratives < ActiveRecord::Migration
  def self.up
    create_table :sub_narratives do |t|
      t.integer :narrative_id
      t.integer :code_id
      t.string :mood
      t.string :authority_code
      t.string :extra

      t.timestamps
    end
    add_column :codes,:typ,:string
    remove_column :codes,:type
  end

  def self.down
    drop_table :sub_narratives
    add_column :codes,:type,:string
    remove_column :codes,:typ 
  end
end
