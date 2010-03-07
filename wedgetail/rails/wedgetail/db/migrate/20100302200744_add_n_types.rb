class AddNTypes < ActiveRecord::Migration
    def self.up
       NarrativeType.create(:id=>'14',:narrative_type_name=>'Document')
       NarrativeType.create(:id=>'15',:narrative_type_name=>'Advanced Care Directive')
       NarrativeType.create(:id=>'16',:narrative_type_name=>'Image')
    end

    def self.down
      NarrativeType.delete(:id=>'14')
      NarrativeType.delete(:id=>'15')
      NarrativeType.delete(:id=>'16')
    end
end
