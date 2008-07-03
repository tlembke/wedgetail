class CreateNarrativeTypes < ActiveRecord::Migration
  def self.up
    create_table :narrative_types do |t|
      t.column :narrative_type_name,        :string
    end
  end

  def self.down
    drop_table :narrative_types
  end
end
