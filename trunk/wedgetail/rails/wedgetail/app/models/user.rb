class User < ActiveRecord::Base

  validates_presence_of :username 
  validates_presence_of :wedgetail
  attr_accessor :password_confirmation 
  validates_confirmation_of :password 
  validates_format_of :postcode,:with=>/^[0-9]{4}$/,:message=>"postcode must be 4 digits",:allow_nil=>true
            
  
  has_many :outbox,
          :class_name => "Message",
          :foreign_key => "sender_id",
          :order => "created_at DESC"
   
  def validate 
    errors.add_to_base("Missing password") if hashed_password.blank? 
    errors.add_to_base("must either have a team or an address") if address_line.blank? and team.blank? and role>2 and role!=7
    errors.add(:town,"must not be empty if address") if town.blank? and not address_line.blank?
    # errors.add(:password,"Password confirmation does not match Password") if password  !=  password_confirmation
    errors.add(:postcode,"must not be empty if address") if postcode.blank? and (not address_line.blank?)
    l = User.find(:all,:conditions=>["wedgetail <> ? and username = ?",wedgetail,username])
    errors.add(:username,"must be unique") unless l.blank? 
    errors.add(:given_names,"real people must have a given name") if (role==5 or role==4) and given_names.blank?
    errors.add(:address_line,"teams must always have an address") if address_line.blank? and role==6
    errors.add(:team,"team captains must have a team") if role==3 and team.blank?
    errors.add(:dob,"patients must have a birthdate") if role==5 and dob.blank?
    unless medicare.blank?
      self.medicare=medicare.delete " -/"
      if medicare =~ /^[0-9]{10}$/
        errors.add(:medicare,"Wedgetail requires Medicare numbers to have 11 digits, the final digit is the one next to the patient's name. If it is not there, use 1.")
      elsif medicare =~ /^[0-9]{11}$/
        check = 0
        [1,3,7,9,1,3,7,9].each_with_index {|mul,i| check+=medicare[i..i].to_i*mul}
        check = check % 10
        errors.add(:medicare,"not a valid Medicare number (fails checksum)") unless check == medicare[8..8].to_i
      else
        errors.add(:medicare,"not a valid Medicare number")
      end
    end
  end 
 
  
  def is_listed(patient_wedgetail)
    is_listed=false
    @ok=Firewall.find(:all,:conditions=>["patient_wedgetail='#{patient_wedgetail}' and user_wedgetail='#{self.wedgetail}'"])
    is_listed=true if @ok.size>0
    return is_listed
  end
  
  def firewall_term(patient_wedgetail)
    firewall_term='Add'
    firewall_term='Remove' if self.is_listed(patient_wedgetail)
    return firewall_term
  end
  
  def password 
    @password 
  end 
  
  def password=(pwd) 
    @password = pwd 
    return if pwd.blank? 
    create_new_salt 
    self.hashed_password = User.encrypted_password(self.password, self.salt) 
  end
  
  def self.authenticate(username, password) 
    user = self.find_by_username(username,:order=>'created_at DESC') 
    if user
      expected_password = encrypted_password(password, user.salt) 
      if user.hashed_password != expected_password 
        user = nil 
      end 
    end 
    user 
  end
  
  def inbox 
    if self.team
      Message.find(:all, :conditions=>["(recipient_id='#{self.wedgetail}' or recipient_id='#{self.team}') and status=0"],:order =>"created_at DESC" )
    else
      Message.find(:all, :conditions=>["recipient_id='#{self.wedgetail}' and status=0"],:order =>"created_at DESC" )
    end
  end
  
  def unhatched
    if self.role==1
      User.find(:all,:conditions=>["role=5 and hatched=0"])
    else
      User.find(:all,:conditions=>["role=5 and hatched=0 and created_by='#{self.wedgetail}'"])
    end
  end
  
  def last_access
    access=Audit.find(:first,:conditions=>["user_wedgetail='#{self.wedgetail}'"],:order =>"created_at DESC" )
    if access
      return access.created_at.strftime("%H:%M %d/%m/%y")
    else
      return ""
    end
  end
  
  def interest(patient)
      @interest=false
      @ok=Interest.find(:all,:conditions=>["patient='#{patient}' and user='#{self.wedgetail}'"])
      @interest=true if @ok.size==1
      return @interest
  end
  
  def interested_parties
      @ips=Interest.find(:all,:conditions=>["patient='#{self.wedgetail}'"])
      @interested_parties=[]
      for @ip in @ips
        @applicant=User.find_by_wedgetail(@ip.user)
        if self.firewall(@applicant)
          @interested_parties<<@applicant
        end
      end
      return @interested_parties
  end

  #check firewall access
  def firewall(applicant)
    firewall=false
    if self.access==1 or self.access=='' or self.access==nil
      firewall = true
    elsif self.access==4
      firewall= true if self.wedgetail==applicant.wedgetail
    elsif self.access==2
      #need to check firewall - black list
      ok=Firewall.find(:all,:conditions=>["patient_wedgetail='#{self.wedgetail}' and (user_wedgetail='#{applicant.wedgetail}' or user_wedgetail='#{applicant.team}')"])
      firewall=true if ok.size==0
    elsif self.access==3
      #need to check firewall - white list
      ok=Firewall.find(:all,:conditions=>["patient_wedgetail='#{self.wedgetail}' and (user_wedgetail='#{applicant.wedgetail}' or user_wedgetail='#{applicant.team}')"])
      firewall=true if ok.size>0 
    end
    return firewall
  end

 def family_name_given_names
   if self.given_names.blank?
     return self.family_name
   else
     return self.family_name+", "+self.given_names
   end
 end

 def full_name
   if self.given_names.blank?
     return self.family_name
   else
     return self.given_names+" "+self.family_name
   end
 end
 
 def team_name
   team_name=""
   team=User.find_by_wedgetail(:first,self.team)
   if team
     team_name=User.family_name
   end
   return team_name
 end 
 
 def birthdate
   return self.dob.day.to_s + "/" + self.dob.month.to_s + "/" + self.dob.year.to_s
 end

  def self.find_current(wedgetail)
    self.find_by_wedgetail(wedgetail,:order=>"created_at DESC")
  end

  def address
    address= self.address_line
    address+=", " if self.address_line!=""
    address+=self.town
  end

  def self.find_fuzzy(familyname,firstname,dob,medicare)
    
    medicare.delete! " -/" if medicare
    familyname.gsub!(%q('),%q(\\\'))
    firstname.gsub!(%q('),%q(\\\'))
    sdob = dob.strftime "%Y-%-m-%-d" # use date that works with database
    if medicare
      n = find_helper(["medicare = ? and dob = ? and family_name like '#{familyname}%' and given_names like '#{firstname}%'", medicare, sdob])
      if n
        n
      else
        n = find_helper(["medicare = ? and dob = ? and given_names like '#{firstname}%'", medicare, sdob])
        if n
          n
        else
          n = find_helper(["medicare = ? and dob = ?", medicare, sdob])
          if n
            n
          else
            find_fuzzy(familyname,firstname,dob,nil)
          end
        end
      end
    else
      n = find_helper(["dob = ? and family_name like '#{familyname}%' and given_names like '#{firstname}%'", sdob])
      if n
        n
      else
        n = find_helper("family_name like '#{familyname}%' and given_names like '#{firstname}%'")
        if n
          n
        else
          n = find_helper("family_name like '#{firstname}%' and given_names like '#{familyname}%'")
          # reversed names -- actually very common
          if n
            n
          else
            n = find_helper(["dob = ? and given_names like '#{firstname}%'", sdob])
            if n
              n
            else
              firstname = firstname.split[0] # use first part of name
              n = find_helper(["dob = ? and given_names like '#{firstname}%' and family_name like '#{familyname}%'", sdob])
              if n
                n
              else
                raise WedgieError, "No unique match to patient using  #{familyname}, #{firstname}, #{dob}"
              end
            end
          end
        end
      end
    end
  end
  
  def self.find_helper(cond)
    n = User.find(:all,:conditions=>cond,:order=>'created_at DESC')
    return nil if n.length == 0
    w = n[0].wedgetail
    for i in n
      if i.wedgetail != w
        return nil
      end
    end
    return n[0]
  end
  
  def find_fuzzier
    clause=Array.new()
    clause << "(dob= '#{self.dob}' and given_names like '#{self.given_names}%%')"
    clause << "(dob= '#{self.dob}' and family_name like '#{self.family_name}')"
    clause << "(family_name like '#{self.family_name}' and given_names like '#{self.given_names}%%')"
    clause << "(family_name like '#{self.given_names}%%' and given_names like '#{self.family_name}')"
    conditions=clause.join(' or ')
    
    matches = User.find(:all,:select => "distinct wedgetail,dob,family_name,given_names ", :conditions => ["wedgetail != '#{self.wedgetail}' and ("+conditions+")"])

  end
  
  # make a HL7 PID segment for this patient
  def make_pid
    pid = HL7::Pid.new
    pid[0] = "PID"
    pid.set_id = 1
    pil = [{:id_number=>wedgetail,:identifier_type_code=>"WEDGIE",
      :assigning_authority=>{:namespace_id=>"Wedgetail",:universal_id=>'wedgetail.medicine.net.au',:universal_id_type=>'DNS'},
      :assigning_facility=>{:namespace_id=>Pref.namespace_id,:universal_id=>Pref.hostname,:universal_id_type=>'DNS'}}]
    if medicare and medicare.length > 0
      pil <<  {:id_number=>medicare,:identifier_type_code=>"MC",:assigning_authority=>{:namespace_id=>"AUSHIC"}}
    end
    pid.patient_identifier_list = pil
    first, second = given_names.upcase.split(" ",2)
    pid.patient_name = {:family_name=>{:surname=>family_name.upcase},:given_name=>first,:second_name=>second}
    pid.date_of_birth = dob
    case sex
    when 1
      pid.sex = "M"
    when 2
      pid.sex = "F"
    end
    pid.patient_address = {:street=>{:street=>address_line},:city=>town,:state=>state,:postcode=>postcode}
    return pid
  end



  private 
  
  def self.encrypted_password(password, salt) 
    string_to_hash = password + "wibble" + salt # 'wibble' makes it harder to guess 
    Digest::SHA1.hexdigest(string_to_hash) 
  end
  
  def create_new_salt 
    self.salt = self.object_id.to_s + rand.to_s 
  end  
  


end
