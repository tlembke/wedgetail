class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.string :title
      t.text :content
      t.int :type
      t.string :created_by
      t.string :team
      t.string :patient
      t.int :condition_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
