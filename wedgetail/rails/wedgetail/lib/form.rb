require 'yaml'

class Form
  @@descendants = {}
  @@regexps = {}
  @@re = nil
  
  def self.logger
    ActiveRecord::Base.logger
  end
  
  def logger
    self.logger
  end
  
  def self.inherited(kls)
    unless kls.name == 'TextForm' or kls.name == 'PrintedForm' or kls.name == 'HL7Form' kls.name.nil?
      @@descendants[kls.name]= kls
      @@regexps[kls.regexp] = kls.name
    end
  end
  
  def self.regexp(re=nil)
    @@re = re if re
    @@re
  end
  
  def self.all_regexps
    @@regexps
  end
  
  def self.form_by_name(name)
    @@descendants[name].new(nil,nil)
  end
  
  def self.search_forms(key)
    return @@descendants.keys.select {|item| item.index(key)}
  end
  
  def self.all_forms
    return @@descendants
  end
  
  def initialize(data=nil,regexp_match=nil)
    if data
      @values = data
    else
      @values = {}
    end
    if regexp_fields
      populate_from_regexp regexp_match
    end
  end
  
  def populate_from_regexp(match)
    # currently do nothing, descendants may override
  end
end

# loads all forms. Forms.inherited gets called as we load these files
Dir.glob(RAILS_ROOT+'/lib/forms/*.rb').each { |fname| load fname }
Dir.glob(RAILS_ROOT+'/lib/forms/*.form').each do |fname| 
  filename =~ /.*\/([a-zA-Z_]+)\.form$/
  name = $1
  klass = eval %q!class #{name} < TextForm ; end ; #{name} !
  klass.setup filename
end