class AddNarrativeTypeData < ActiveRecord::Migration
  def self.up
    NarrativeType.delete_all
    NarrativeType.create(:id=>'1',:narrative_type_name=>'Health Summary')
    NarrativeType.create(:id=>'2',:narrative_type_name=>'Medication Chart')
    NarrativeType.create(:id=>'3',:narrative_type_name=>'Discharge Summary')
    NarrativeType.create(:id=>'4',:narrative_type_name=>'Encounter')
    NarrativeType.create(:id=>'5',:narrative_type_name=>'Allergies')
    NarrativeType.create(:id=>'6',:narrative_type_name=>'Scratchpad') 
    NarrativeType.create(:id=>'7',:narrative_type_name=>'Results')    
    NarrativeType.create(:id=>'8',:narrative_type_name=>'Letter') 
    NarrativeType.create(:id=>'9',:narrative_type_name=>'Immunisations')
    NarrativeType.create(:id=>'10',:narrative_type_name=>'Form') 
    NarrativeType.create(:id=>'11',:narrative_type_name=>'Prescription')
    NarrativeType.create(:id=>'12',:narrative_type_name=>'Diagnosis')
  end

  def self.down
    NarrativeType.delete_all
  end
end