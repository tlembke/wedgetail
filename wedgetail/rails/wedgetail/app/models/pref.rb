class Pref < ActiveRecord::Base
#  Unhatched Access = NULL or 1 => No access by anyone
#  Unhatched Access = 2 => access by user who created patient
#  Unhatched Access = 3 => access by team of user who created patient
#  Unhatched Access = 4 => access by patient only
#  Hatched Access = 1=> all providers
# Hatched Access = 2=> keep unhatched access


  def self.list
    {
      :server=>{:name=>'Server Wedgetail code',:default=>'0000'},
      :time_out=>{:name=>'Timeout',:default=>10},
      :use_ssl=>{:name=>'Use SSL',:default=>false},
      :namespace_id=>{:name=>"HL7 Namespace ID",:default=>"Main Wedgetail Server"},
      :hostname=>{:name=>"Hostname",:default=>"localhost"},
      :email=>{:name=>"Server E-mail Address",:default=>""},
      :max_sends=>{:name=>"Maximum send attempts",:default=>3},
      :host_url=>{:name=>"Host URL",:default=>"wedgetail.org.au"},
      :theme=>{:name=>"Theme",:default=>"wedgetail"},
      :toolbar=>{:name=>"Toolbar",:default=>true},
      :unhatched_access=>{:name=>"Unhatched Access",:default=>3},
      :hatched_access=>{:name=>"Hatched Defauly Access",:default=>1}
    }
  end

  def self.method_missing(method,val=nil)
    if self.list.has_key? method
      thisPref=Pref.find_by_name(method.to_s)
      default = self.list[method][:default]
      if thisPref.nil?
        return default
      else
        if default == true or default == false
          return thisPref.value == "TRUE"
        elsif default.kind_of? Integer
          return thisPref.value.to_i
        else
          return thisPref.value
        end
      end
    else
      super(method,val)
    end
  end
  
  def self.update_attributes(newdict)
    errors = {}
    newdict.each_pair do |key,val|
      key = key.to_sym
      if self.list.has_key? key
        errors[key] = self.set(key, val)
      end
    end
    return errors
  end
  
  def self.set(config,val)
    default = self.list[config][:default]
    logger.debug("config: %p val: %p" % [config,val])
    if default == true or default == false
      if val==true or val=="1" or val=="TRUE"
        val = true
        nval = "TRUE"
      else
        val = false
        nval = "FALSE"
      end
    elsif default.kind_of? Integer
      nval = val.to_s
      return "Must be valid integer" unless /[0-9\-\+]+/ =~ nval
    elsif default == 'localhost'
      return "Must be valid hostname" unless /[a-zA-Z\.\-_]+/ =~ val
      nval = val.to_s
    else
      nval = val.to_s
    end
    thisPref = Pref.find_by_name(config.to_s)
    if thisPref.nil? 
      Pref.new({:name=>config.to_s,:value=>nval}).save! unless val == default
    elsif thisPref.value != nval
      thisPref.value = nval
      thisPref.save!
    end
    return nil
  end

end
