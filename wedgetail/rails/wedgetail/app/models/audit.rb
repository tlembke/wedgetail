class Audit < ActiveRecord::Base
   
  def user
    @user=User.find_by_wedgetail(self.user_wedgetail)
  end
  
  def self.ecollabpatients
        ecollabpatients=Audit.find_by_sql("select audits.patient from audits,users patient, users provider where audits.patient = patient.wedgetail and audits.user_wedgetail=audits.patient and provider.wedgetail=patient.created_by and provider.hatched=1").count
  end
end
