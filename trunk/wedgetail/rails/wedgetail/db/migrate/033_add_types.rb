class AddTypes < ActiveRecord::Migration
  def self.up
    NarrativeType.create(:id=>'7',:narrative_type_name=>'Result')
    NarrativeType.create(:id=>'8',:narrative_type_name=>'Letter')
    NarrativeType.create(:id=>'9',:narrative_type_name=>'Immunisations')
  end

  def self.down
    NarrativeType.delete(:id=>'7')
    NarrativeType.delete(:id=>'8')
    NarrativeType.delete(:id=>'9')
  end
end
