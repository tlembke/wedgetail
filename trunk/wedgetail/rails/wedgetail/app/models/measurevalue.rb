class Measurevalue < ActiveRecord::Base
  belongs_to :measure
  
  def self.find_with_limit(patient,measure_id,start=0,limit=10)
    @measurevalues=Measurevalue.find(:all,:conditions => ["patient=? and measure_id=?",patient,measure_id],:limit=>limit,:offset=>start,:order =>"value_date DESC")
    @count=Measurevalue.count(:conditions => ["patient=? and measure_id=?",patient,measure_id])
    more_flag=true
    more_flag=false if start+limit>=@count
    return [@measurevalues,@count,start,limit,more_flag]
  end
  
  def self.build_table(patient,measure_id,number_rows=10,limit=100)
    @measurevalues=Measurevalue.find(:all,:conditions => ["patient=? and measure_id=?",patient,measure_id],:limit=>limit,:order =>"value_date DESC")
    rows=[]
    row=[]
    count=0
    @measurevalues.each do |@measurevalue|
      count=count+1
      set=[@measurevalue.value_date,@measurevalue.value]
      row<<set
      if count==number_rows
        rows<<row
        row=[]
        count=0
      end
    end
    if row.count>0
      rows<<row
    end
    return rows
  end
  
  def self.color(value,measure,color_met='green',color_not_met='red')
    if measure.places==0 or measure.places==""
      value=value.to_i
    else
      value=value.round(measure.places)
    end
    text=value.to_s
    if measure.operator and measure.value
      color_to_use=color_not_met
      operator=measure.operator_string
      operator="==" if operator=="="
      expression=text+operator+measure.value.to_s
      if eval(expression)
        color_to_use=color_met
      end
      text="<font color='"+color_to_use+"'>"+value.to_s+"</font>"
    end
    return text
  end
    
end
