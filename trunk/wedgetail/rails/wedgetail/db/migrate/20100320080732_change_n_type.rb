class ChangeNType < ActiveRecord::Migration
  def self.up
     NarrativeType.find(15).update_attribute "narrative_type_name", "Advance Care Directive"
  end

  def self.down
  end
end
