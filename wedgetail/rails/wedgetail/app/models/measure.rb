class Measure < ActiveRecord::Base
  has_one :goal
  has_many :measurevalues, :order => "created_at DESC"
  
  def operator_string
    operators=["","<",">","=","<=",">="]
    return operators[self.operator]
  end
  
  def self.operators_hash
    theHash = [["<",1],[">",2],["=",3],["<=",4],[">=",5]]
    return theHash
  end
  
  def latest(patient,target=true,date=true)
    if @latest=Measurevalue.find(:first,:conditions => ["patient=? and measure_id=?",patient,self.id],:order =>"value_date DESC")
      value=round_value(@latest.value,self.places)
    else
      value="..."
    end
    value=value.to_s+" "+self.units
    if target and self.value
      target=round_value(self.value,self.places)
      text=" ("+self.operator_string+" "+target.to_s+")"
      value=value+text
    end
    if date and @latest
      value=value+" on "+ @latest.value_date.strftime("%d/%m/%y")
    end
    return value
  end
  
  def round_value(value,places)
    if self.places==0 or places==""
      value=value.to_i
    else
      value=value.round(places)
    end
  end
end
