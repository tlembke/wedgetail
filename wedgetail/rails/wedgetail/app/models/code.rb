class Code < ActiveRecord::Base
  serialize :values


  @@codes = nil

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

  def javascript_line
    nym = self.class.name.downcase
    return "{typ:'#{nym}',name:'#{name}'}"
  end


  def self.load_codes
    Code.delete_all
    Dir.glob(File.join(File.dirname(__FILE__), "../../db/migrate/codes_data/*.yml")) do |fname|
      File.open(fname) do |f| 
        YAML.load_documents(f) do |value| 
          d= {}
          d[:code] = value.delete("code")
          d[:name] = value.delete("name")
          d[:type] = fname[0..-5].camelize.singularize
          d[:values] = values unless values.blank?
          Code.new(d).save!
        end
      end
    end
    Drug.process_pbs
  end

  def get_text(patient)
    {"text"=>"","comment"=>""}
  end
end



class Diagnosis < Code # OID 4,

  def to_html(text,narr)
    "<b>diagnosed:</b> "+name
  end

end

class PathologyRequest < Code # OID 3.1.
end

class ImagingRequest < Code # OID 3.2.
end

# a specific individual
class Referrer < Code # OID 3.3. 
end


# a referral discipline (so we pop up an addressbook selector)
class Referral < Code
end

