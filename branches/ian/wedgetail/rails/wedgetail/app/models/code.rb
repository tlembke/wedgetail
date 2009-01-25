class Code < ActiveRecord::Base
  serialize :values


  @@codes = nil

  def self.accept_code?(code)
    true
  end

  def self.class_by_code(code)
    ret = nil
    ObjectSpace.each_object(Class) do |klass|
      if klass < Code and klass.accept_code?(code)
        ret = klass
      end
    end
    ret = Code if ret.nil?
    ret
  end

  def self.all_codes
    unless @@codes
      @@codes = {}
      Code.find(:all).each do |c|
        @@codes[c.name] = c
      end
    end
    @@codes
  end

  # return the appropriate object for a clinical phrase (the contents of {})
  def self.get_clinical_object(text,narr)
    s = text.split(';')
    c = all_codes[s[0]]
    if c
      return SubNarrative.new(c,(s[1] or ''),narr)
    else
      return nil
    end
  end

  def gen_pdf(text,pdf,user,patient)
  end # NOP

  def can_print?(text,narr)
    false
  end

  def delete?(text,narr)
    not((text =~ /delete/).nil?)
  end

  def to_html(text,narr)
    "<b>"+name+"</b> "+text
  end


  def self.load_codes
    Code.delete_all
    Dir.glob(File.join(File.dirname(__FILE__), "../../db/migrate/codes_data/*.yml")) do |fname|
      File.open(fname) do |f| 
        YAML.load_documents(f) do |value| 
          Code.class_by_code(value["code"]).new(value).save!
        end
      end
    end
  end
end

class Drug < Code
  def javascript_line
    return "{typ:'drug',name:'#{name}',popup:null,values:'#{values['instr']} qty #{values['qty']} rpt #{values['rpt']}'}"
  end

  def self.accept_code?(code)
    code.starts_with?("1.3.6.1.4.1.18298.2.")
  end


  def gen_pdf(text,narr,pdf)
    author = User.find_by_wedgetail(narr.created_by,:order=>"created_at desc")
    patient = narr.user
    team = User.find_by_wedgetail(author.team,:order=>"created_at desc")
    text.sub!(/qty:? *([0-9]+)(|ml|g) *rpt:? *([0-9]+)/i,"\nAmount: \\1 Repeats: \\3")
    text.sub!(/auth(ority)?:? ?([0-9a-zA-Z]+)/i,"\nAuthority: \\1")
    [0,105].each do |x|
      pdf.SetXY(x+25,21)
      pdf.Cell(70,6,author.prescriber)
      pdf.SetXY(x+24,53)
      pdf.Cell(70,6,patient.full_name)
      pdf.SetXY(x+24,58)
      pdf.MultiCell(70,5,patient.full_address)
      pdf.SetXY(x+10,68)
      pdf.Cell(80,6,narr.created_at.strftime("%d/%m/%Y"))
      unless text =~ /non\-?pbs/i
        unless patient.dva.blank?
          pdf.SetXY(x+23,35)
          pdf.Cell(75,6,patient.dva)
          pdf.SetXY(x+28,72)
        else
          pdf.SetXY(x+10,72)
        end
        pdf.Cell(8,6,"X",0,0,"L")
      end
      pdf.SetXY(x+25,90)
      pdf.MultiCell(65,5,name)
      pdf.SetXY(x+30,95)
      pdf.MultiCell(60,5,text+"\n\n\n\n"+author.full_name,0,"L")
    end      
  end


  def can_print?(text,narr)
    # FIXME: should validate text at this point
    true
  end

  def remaining(text,narr)
    # try to compute quantity remaining. 0 means run out, -1 means can't compute
    return -1 unless text =~ /qty:? *([0-9]+)(|ml|g) *rpt:? *([0-9]+)/i
    qty = $1.to_i
    rpt = $3.to_i
    unit = $2
    total = qty*(rpt+1)
    return -1 unless text =~ /([0-9\.]*) ?#{unit} ?(mane|nocte|bd|bid|tds|tid|qid|qds|od|daily)/
    if $1.blank?
      dose = 1
    else
      dose = $1.to_i
    end
    case $2
      when "od","mane","nocte","daily"
      dose = dose
      when "bd","bid"
      dose *= 2
      when "tds","tid"
      dose *= 3
      when "qid","qds"
      dose *= 4
    end
    days_ago = (Time.now-narr.created_at)/3600/24
    remaining = total - (days_ago*dose).to_i
    remaining = 0 if remaining < 0
    return remaining
  end
end

class Diagnosis < Code # OID 4,
  def self.accept_code?(code)
    code.starts_with?('1.3.6.1.4.1.18298.4.')
  end

  def javascript_line
    return "{typ:'diagnosis',name:'#{name.gsub("'","\\'")}',popup:null,values:''}"
  end

  def to_html(text,narr)
    "<b>diagnosed:</b> "+name
  end
end

class PathologyRequest < Code # OID 3.1.
  def self.accept_code?(code)
    false
  end
end

class ImagingRequest < Code # OID 3.2.
  def self.accept_code?(code)
    false
  end
end

# a specific individual
class Referrer < Code # OID 3.3. 
  def self.accept_code?(code)
    x = code.split('.')
    code.starts_with?('1.3.6.1.4.1.18298.3.3.') and x.length >= 14
  end
end


# a referral discipline (so we pop up an addressbook selector)
class Referral < Code
  def self.accept_code?(code)
    x = code.split('.')
    code.starts_with?('1.3.6.1.4.1.18298.3.3.') and x.length < 14
  end

  def javascript_line
    return "{typ:'refer',name:'#{name}',popup:null,values:'referral'}"
  end
end

