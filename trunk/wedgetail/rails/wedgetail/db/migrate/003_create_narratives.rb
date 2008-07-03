class CreateNarratives < ActiveRecord::Migration
  def self.up
    create_table :narratives do |t|
      t.column :patient_id,         :integer
      t.column :narrative_type,     :integer
      t.column :narrative_title,    :string
      t.column :narrative_content,  :text
      t.column :narrative_date,     :date
      t.column :user_id,            :integer
      t.column :created_at,         :timestamp
      
    end
  end

  def self.down
    drop_table :narratives
  end
end
