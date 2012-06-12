class EcollabsController < ApplicationController
layout "standard"
  
  def index
     @stats={:patients=>User.count(:conditions =>"role=5"),
             :summaries=>Narrative.find(:all,:group => :wedgetail,:conditions => "narrative_type_id=1").count,
             :ecollabsummaries=>Narrative.ecollabsummaries,
             :ecollabpatients=>User.ecollabpatients,
             :ecollabaudits=>Audit.ecollabpatients,
             :ecollabusers=>User.ecollabusers,
             :medications=>Narrative.find(:all,:group => :wedgetail,:conditions => "narrative_type_id=2").count,
             :narratives=>Narrative.count,
             :users=>User.count(:conditions =>"role<5"),
             :audits=>Audit.count,
             :audits_week=>Audit.count(:conditions => ['created_at > ?', 1.week.ago]),
              :audits_month=>Audit.count(:conditions => ['created_at > ?', 1.month.ago]),
              :audits_last_week=>Audit.count(:conditions => ['created_at < ? and created_at >?', 1.week.ago, 2.weeks.ago]),
              :audits_last_month=>Audit.count(:conditions => ['created_at < ? and created_at >?', 1.month.ago, 2.months.ago]),
             
           }
      respond_to do |format|
              format.html 
              format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
              format.xml { render :xml => @stats, :template => 'stats/stats.xml.builder' }
      end
     
  end
end
