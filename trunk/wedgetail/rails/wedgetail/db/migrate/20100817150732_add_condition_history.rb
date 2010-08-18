class AddConditionHistory < ActiveRecord::Migration
  def self.up
     NarrativeType.create(:id=>'18',:narrative_type_name=>'Condition History')
  end

  def self.down
    NarrativeType.delete(:id=>'18')
  end
end

