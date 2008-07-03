class AddNarrativeTypeData < ActiveRecord::Migration
  def self.up
    NarrativeType.delete_all
    NarrativeType.create(:id=>'1',:narrative_type_name=>'Health Summary')
    NarrativeType.create(:id=>'2',:narrative_type_name=>'Medication Chart')
    NarrativeType.create(:id=>'3',:narrative_type_name=>'Discharge Summary')
    
  end

  def self.down
    NarrativeType.delete_all
  end
end
