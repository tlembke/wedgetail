require "open3"
require "date"
include Open3

class PrintedForm < Form
  # methods for forming form definitions
  
  @@fields = []
  
  def self.add_field(x,y,page,name,print_name,type,doc=nil,opts={})
    @@fields+=opts.merge({:x=>x,:y=>y,:page=>page,:name=>name,:print_name=>print_name,:type=>type,:doc=>doc})
  end
  
  def self.add_internal_field(x,y,page,type,opts={})
    @@fields+=opts.merge({:type=>type,:x=>x,:y=>y,:page=>page})
  end
  
  def self.vline(x,y,page,length)
    @@fields+={:type=>:vertical_line,:x=>x,:y=>y,:page=>page,:length=>length}
  end
  
  def self.hline(x,y,page,length)
    @@fields+={:type=>:horiz_line,:x=>x,:y=>y,:length=>length,:page=>page}
  end
  
  def fields
    @@fields.select {|x| x[:name] }
  end
  
  def set(key,value)
    @values[key] = value
  end
  
  def get_field(key)
    @@fields.each {|x| return x if x[:name]==key }
  end
  
  # update from a web form
  # returns a dictionary of errors
  def update(params)
    errors = {}
    params.each_pair do |key,value|
      field = get_field key
      case field[:type]
      when :text,:string
        @values[key] = value
      when :regexp_text
        if value =~ field[:regexp]
          @values[key] = value
        else
          errors[key] = "Invalid value"
        end
      when :date,:relative_date
        if value =~ /([0-9]+)\/([0-9]+)\/([0-9]+)/
          @values[key] = Date.civil($3.to_i,$2.to_i,$1.to_i)
        else
          errors[key] = "date must be in the format DD/MM/YY"
        end
      when :boolean
        if value == "Y" or value == "y" or value == "yes" or value == "true"
          @values[key] = true
        elsif value == "N" or value == "n" or value == "no" or value == "false"
          @values[key] = false
        else
          errors[key] = "boolean value %s is ambiguous" % value
        end
      end
    end
    return errors
  end
  
  def print(patient,doctor,dest)
    page = 1
    items = nil
    fpdf = FPDF.new
    fpdf.SetDrawColor(0,0,0)
    until items == []
      fpdf.AddPage
      items = @@fields.select {|x| x[:page] == page}
      items.each do |field|
        case field[:type]
        # fields for automatic values
        when :fixed_text
          print_at(fpdf,field,field[:text])
        when :patient_name
          print_at(fpdf,field,patient.full_name)
        when :patient_family_name
          print_at(fpdf,field,patient.family_name)
        when :patient_given_names
          print_at(fpdf,field,patient.given_names)
        when :patient_dob
          print_at(fpdf,field,patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s)
        when :patient_address
          print_at(fpdf,field,patient.address_line + "\n" + patient.town + " "+patient.postcode+"\n")
        when :medicare
          print_at(fpdf,field,patient.medicare)
        when :doctor_name
          print_at(fpdf,field,doctor.full_name)
        when :doctor_family_name
          print_at(fpdf,field,doctor.family_name)
        when :doctor_given_names
          print_at(fpdf,field,doctor.given_names)
        when :doctor_dob
          print_at(fpdf,field,doctor.dob.day.to_s + "/" + doctor.dob.month.to_s + "/" +doctor.dob.year.to_s)
        when :doctor_address
          print_at(fpdf,field,doctor.address_line + "\n" + doctor.town + " "+doctor.postcode+"\n")
        # in the future there will be more complex types such as :patient_medication_list
        # which will trigger the appropriate queries using patient.wedgetail and display this data
        # FIXME: we need provider_number and prescriber_number fields somewhere
        
        # these are the custom fields
        when :text,:regexp_text,:string
          print_at(fpdf,field,@values[field[:name]])
        when :date,:relative_date
          d = @values[field[:name]]
          print_at(fpdf,field,d.day.to_s+"/"+d.month.to_s+"/"+d.year.to_s)
        when :boolean
          if @values[field[:name]]
            t = field[:true_text]
          else
            t = field[:false_text]
          end
          print_at(fpdf,field,t)
        
        
        # line drawing "fields" for Terry-style custom forms
        when :vertical_line
          fpdf.SetLineWidth(field[:width]) if field[:width]
          fpdf.Line(field[:x],field[:y],field[:x]+field[:length],field[:y])
        when :horiz_line
          fpdf.SetLineWidth(field[:width]) if field[:width]
          fpdf.Line(field[:x],field[:y],field[:x],field[:y]+field[:length])
        end
      end
      page += 1
    end
    fpdf.Close
    pdf = fpdf.Output
    if dest == "" or dest == "pdf"
      return pdf
    else
      # send to printer
      if dest=="default"
        cmd="lpr"
      else
        cmd = "lpr -P %d" % dest
      end
      unless RUBY_PLATFORM =~ /darwin/
        # apparently Mac printer drivers understand PDF natively
        cmd = "pdf2ps -sOutputFile=- -q - | %s" % cmd
      end
      IO.popen(cmd,"w") { |f| f.print(pdf) }
      return nil
    end
  end
  
  private
  
  def print_at(fpdf,field,text)
    field = {:font=>'Arial',:size=>12,:style=>'',:width=>0,:align=>''}.merge(field)
    fpdf.SetXY(field[:x],field[:y])
    fpdf.SetFont(field[:font],field[:style],field[:size])
    fpdf.MultiCell(field[:width],0,field[:text],0,field[:align])
  end
end