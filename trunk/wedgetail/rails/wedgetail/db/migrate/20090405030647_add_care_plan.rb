class AddCarePlan < ActiveRecord::Migration
  def self.up
     NarrativeType.create(:id=>'13',:narrative_type_name=>'Care Plan')
  end

  def self.down
    NarrativeType.delete(:id=>'13')
  end
end
