class Condition < ActiveRecord::Base
  has_many :measures
  has_many :goals
  
  def summary(patient)
      unless @summary=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=18 and condition_id=?",patient,self.id], :order=>"narrative_date DESC,created_at DESC")
          #we need to create a new summary even if blank as the patient wedgetail is not passed with the AJAX in_line_edit call
         @summary=Narrative.create(:wedgetail=>patient,:narrative_type_id=>18,:condition_id=>self.id,:content=>"",:content_type=>"text/plain")
       end
       return @summary
  end
end
