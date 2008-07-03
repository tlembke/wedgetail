class AddMoreNarrativeTypeData < ActiveRecord::Migration
  def self.up
    NarrativeType.create(:id=>'4',:narrative_type_name=>'Encounter')
    NarrativeType.create(:id=>'5',:narrative_type_name=>'Allergies')
    NarrativeType.create(:id=>'6',:narrative_type_name=>'Scrapbook')
  end

  def self.down
    NarrativeType.delete(:id=>'4')
    NarrativeType.delete(:id=>'5')
    NarrativeType.delete(:id=>'6')
  end
end
