class RenameScrapbook < ActiveRecord::Migration
  def self.up
    narrative_type = NarrativeType.find(6)
    narrative_type.update_attribute(:narrative_type_name, "Scratchpad")
  end

  def self.down
    narrative_type = NarrativeType.find(6) 
    narrative_type.update_attribute(:narrative_type_name, "Scrapbook")
  end
end
