class AddYetMoreNarrativeTypeData < ActiveRecord::Migration
  def self.up
    NarrativeType.create(:id=>'10',:narrative_type_name=>'Form')
    NarrativeType.create(:id=>'11',:narrative_type_name=>'Prescription')
    NarrativeType.create(:id=>'12',:narrative_type_name=>'Diagnosis')
  end

  def self.down
    NarrativeType.delete(:id=>'10')
    NarrativeType.delete(:id=>'11')
    NarrativeType.delete(:id=>'12')
  end
end
