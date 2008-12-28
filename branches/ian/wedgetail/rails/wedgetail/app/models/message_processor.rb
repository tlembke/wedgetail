# common code for processing incoming messages, either via e-mail, web upload or API.
# Note this class does not refer to a backend table
class MessageProcessor

  # detect the MIME type using complex heuristics
  # - +file+ the file in question, as a string
  # - +content_type+ the MIME type as passed in by the transport layer. Can be nil.
  # - +name+ the name as passed by the transport layer, uses the file ending can be nil.
  def self.detect_type(file,content_type,name)
    mime= nil
    case content_type
      when 'application/msword','application/x-msword','application/x-ms-word'
        mime='application/x-ms-word'
      when 'application/rtf','application/x-rtf','text/rtf'
        mime='application/x-rtf'
      when 'application/x-pit','application/pit','text/pit'
        mime='application/x-pit' # standardise the MIME name
      when 'application/edi-hl7','application/x-hl7','application/x-edi-hl7','text/hl7'
        mime = 'application/edi-hl7'
      when 'text/plain'
        mime='text/plain'
      when 'application/x-pkcs7-mime','application/pkcs7-mime'
        mime='application/x-pkcs7-mime'
    else
      case name
        when /.+\.doc$/i then mime = 'application/x-ms-word'
        when /.*\.pit$/i then mime = 'application/x-pit'
        when /.*\.rtf$/i then mime = 'application/x-rtf'
        when /.*\.hl7$/i then mime = 'application/edi-hl7'
        when /.*\.txt$/i then mime = 'text/plain'
      end
    end
    word_magic = "\320\317\021\340\241\261\032\341" # magic number to identify wordfiles
    if mime.nil? or mime == 'text/plain'
      # as a last-ditch attempt, we try to infer the filetype directly
      logger.debug("file = %p" % file)
      if file.starts_with? "{\\rtf"
        mime = 'application/x-rtf'
      elsif file.starts_with?("MSH|") || file.starts_with?("FHS|") || file.starts_with?("BHS|")
        mime = 'application/edi-hl7'
      elsif file[0,word_magic.length] == word_magic
        mime = 'application/x-ms-word'
      elsif file =~ /-----BEGIN PGP MESSAGE-----/
        mime = 'application/x-openpgp'
      elsif file =~ /001 /
        mime = 'application/x-pit'
      end
    end
    if mime.nil?
      if file =~ /^Re:.*/ or file =~ /wedgetail *: */i
        mime = 'text/plain'
      end
    end
    mime
  end
  # - +logger+ the Rails logger instance. 
  # - +user_id+ the value for User.id for the user doing the upload
  # - +file+ the file to be uploaded
  # - +content_type+ the content type, must be from detect_type
  # - +plaintext+ the plaintext representation, if appropriate (generally for RTF)
  def initialize(logger,user_id,file,content_type,plaintext=nil)
    @query = nil
    @narrs = []
    @status = "no action performed"
    @wedgetail = nil
    @logger = logger
    @logger ||= ActiveRecord::Base.logger
    upload(user_id,file,content_type,plaintext)
  end
  
  # the Rails logger, for compatibility with the rest of the framework
  def logger
    @logger
  end
  
  def self.logger
    ActiveRecord::Base.logger
  end
  
  # as for new
  def upload(user_id,file,content_type,plaintext=nil)
    ret = nil
    data = {:narrative_type_id=>4,:discard=>false}
    case content_type
      when 'application/x-ms-word'
        file,plaintext = MessageProcessor.make_html_text_from_doc(file)
        upload(user_id,file,'text/html',plaintext)
      when 'application/x-rtf'
        file,plaintext = MessageProcessor.make_html_text_from_rtf(file)
        upload(user_id,file,'text/html',plaintext)
      when 'application/x-pit'
        file = file.gsub "\r\n","\n" # normalise the newlines
        file.gsub! "\n\r","\n"
        file.gsub! "\r","\n"
        raise WedgieError,"Invalid PIT format - no patient name" unless /^100 Start Patient *: +([^,]+),(.+)$/i =~ file
        data[:familyname] = $~[1].strip
        data[:firstname] = $~[2].strip
        raise WedgieError,"Invalid PIT format - no patient DOB" unless /^104 +Birthdate ?: +([^ ]+) *.*$/i =~ file
        data[:dob] = get_date($~[1])
        raise WedgieError,"Invalid PIT format - no Medicare number" unless /^112 Medicare Number ?: +(.+)$/i =~ file
        data[:medicare] = $~[1].strip
        raise WedgieError,"Invalid PIT format - no report date" unless /^206 Reported ?:? (.*)/ =~ file
        data[:narrative_date] = get_date($~[1])
        data[:narrative_type_id] = 3 if /^205.*Discharge Summary/i =~ file
        data[:narrative_type_id] = 8 if /^205.*Letter/i =~ file
        data[:narrative_type_id] = 7 if /^205.*Investigation/i =~ file
      when 'application/edi-hl7'
        begin
          if file.is_a? HL7::Message
            hl7 = file
            file = hl7.to_hl7
          else
            hl7 = HL7::Message.parse(file)
          end
          data = process_hl7(user_id,hl7)
        rescue HL7::Error
          raise WedgieError,'HL7 error: %s' % $!
        end
      when 'text/plain' 
        data=process_text(file)
      when 'text/html'
        data=process_text(plaintext)
    end
    if data[:familyname] and ( ! data[:wedgetail])
      begin
        patient = User.find_fuzzy(data[:familyname], data[:firstname], data[:dob], data[:medicare])
        data[:wedgetail] = patient.wedgetail
      rescue WedgieError
        if data[:create]
          patient = User.new({:family_name=>data[:familyname],:given_names=>data[:firstname],:address_line=>data[:address_line],:town=>data[:town],:dob=>data[:dob],:medicare=>data[:medicare],:sex=>data[:sex],:dva=>data[:dva],:crn=>data[:crn],:password=>data[:password],:postcode=>data[:postcode],:password_confirmation=>data[:password]})
          # generate temporary wedgetail number
          wedgetail_number = WedgePassword.make("H")
          patient.wedgetail = wedgetail_number
          patient.username = wedgetail_number
          patient.role = 5
          patient.hatched = 0
          patient.created_by = user_id
       	  begin 
            patient.save!
            @status = "new patient created"
            @wedgetail = wedgetail_number
            logger.info "creating new patient from document"
            data[:wedgetail] = wedgetail_number
      	  rescue ActiveRecord::RecordInvalid
            raise WedgieError,"could not create patient due to %s" % $!.to_s
          end
        else
          raise
        end
      end
    end
    if data[:wedgetail] and (! data[:discard])
      patient = User.find_by_wedgetail(data[:wedgetail],:order=>"created_at DESC")
      raise WedgieError, 'wedgetail no %s not valid' % data[:wedgetail] unless data[:wedgetail]
      data[:narrative_date] ||= Time.now
      d = {:wedgetail=>data[:wedgetail],:content_type=>content_type,:content=>file,:created_by=>user_id,:narrative_type_id=>data[:narrative_type_id],:narrative_date=>data[:narrative_date]}
      if plaintext
        d[:plaintext] = plaintext
      end
      narr = Narrative.new d
      logger.info "created new narrative %p" % narr
      @narrs << narr
    end
  end
  
  # extract wedgetail number from HL7, or handle ACKs as appropriate
  def process_hl7(user_id,hl7)
    ret = wedgetail = patient = nil
    if hl7.multi?
      logger.info "Multiple HL7 found"
      hl7.divide.each do |m| 
         upload(user_id,m,'application/edi-hl7',nil)
      end
      return {}
    end
    logger.info "message type is %s" % hl7.msh.message_type.message_code
    case hl7.msh.message_type.message_code
    when "ACK"
      logger.info "HL7 ACK recognised"
      begin
        om = OutgoingMessage.find(hl7.msa.control_id.to_i(16)) # our control ID is the row ID in hex
        om.acked(hl7)
        om.save!
        @status = "HL7 ACK processed"
      rescue ActiveRecord::RecordNotFound
        # we couldn't find a message
        # however this is an ACK -- so we log the problem but we don't raise an error
        # as this would cause an ack itself to be sent and cause a mail loop
        logger.error "unable to process HL7 ACK"
        logger.error hl7
      end
      return {}
    when "ORU"
      if hl7.pid.patient_name[0].blank? && hl7.obx.identifier.identifier.ends_with?(".pit")
        # it's an Argus-style message purely used to encapsulate PIT
        upload(user_id,hl7.obx.value[0],'application/x-pit',nil)
      elsif ! hl7.pid.patient_name[0].blank?
        wedgetail = wedgetail_from_pid hl7.pid
        narrative_type_id = 7
      else
        raise WedgieError, "Unable to determine valid PID segment"
      end
    when "REF","RRI"
      wedgetail = wedgetail_from_pid hl7.pid
      narrative_type_id = 8
    else
      raise WedgieError, "HL7 type %s not supported yet" % hl7.msh.message_type.message_code
    end
    return {:wedgetail=>wedgetail,:narrative_type_id=>narrative_type_id}
  end
  
  def wedgetail
    @wedgetail
  end

  def status
    @status
  end

  # extract wedgetail from PID segment of HL7
  def wedgetail_from_pid(pid)
    wedgetail = patient = medicare = nil
    dob = pid.date_of_birth.time
    pid.patient_identifier_list.each do |p|
      if p.identifier_type_code == "MC"
        medicare = p.id_number
      elsif p.identifier_type_code == "WEDGIE"
        wedgetail = p.id_number
        raise WedgieError,"bogus wedgetail number %s in HL7" % wedgetail unless User.find_by_wedgetail(wedgetail)
      end
    end
    patient = nil
    if ! wedgetail
      pid.patient_name.each do |name| # check each name provided
        begin
          patient = User.find_fuzzy(name.family_name.surname,name.given_name,dob,medicare)
        rescue WedgieError
        end
      end
      raise WedgieError, "no match to patient from HL7 data" unless patient
      wedgetail = patient.wedgetail
    end
    wedgetail
  end
  
  # make a HL7 ack if neccessary
  def form_hl7_response(hl7)
    if @narrs
      hl7.ack
    elsif @query
      @query.to_hl7
    end
  end
  
  # save the narrative(s) if it/they exist(s).
  def save
    @narrs.each do |narr|
      narr.save
      narr.sendout
      @status = "File successfully uploaded" if @status == "no action performed"
    end
  end
  
  # this and the other make_XXX encapsulate code that is specific to using Abiword as our processor for proprietary formats
  # if we want to replace it when the interfaces of make_html_XXX functions should be preserved
  
  def self.make_html_text_from_doc(file)
    abiwordise('doc.doc',file,true)
  end
  
  def self.make_html_text_from_rtf(file)
    abiwordise('doc.rtf',file,true)
  end
  
  def self.make_html_from_doc(file)
    abiwordise('doc.doc',file,false)
  end
  
  def self.make_html_from_rtf(file)
    abiwordise('doc.rtf',file,false)
  end

  def self.make_html_from_text(c)
    x = c.gsub("&","&amp;")
    x.gsub!("<","&lt;")
    x.gsub!(">","&gt;")
    x.gsub!('"',"&quot;")
    x.gsub!("\n\n","<p/>")
    x.gsub!("\r\n\r\n","<p/>")
    x.gsub!("\n","<br/>")
    return x
  end

  # search for a Re: line or wedgetail: XX in the text and match patient accordingly.
  # Returns a list +[wedgetail,familyname,firstname,dob,narrative_date]+
  # either wedgetail or the other values will be nil, if both are nil then matching failed.
  def process_text(file)
    file = file.gsub "\r\n","\n" # normalise the newlines
    file.gsub! "\n\r","\n"
    file.gsub! "\r","\n"
    logger.info "TEXT FILE: %p" % file
    r = {:wedgetail=>nil,:discard=>false,:create=>false}
    if /wedgetail *: *([0-9a-zA-Z]+)/i =~ file
      r[:familyname] = r[:firstname] = r[:dob] = nil
      r[:wedgetail] = $1
    else
      raise WedgieError,"No Wedgetail: or Re: line found" unless /^Re ?:?(.*)$/i =~ file
      re_line = $~[1]
      raise WedgieError,"No name found" unless /([A-Za-z][A-Za-z'\- ]+),([A-Za-z'\- ]+)/i =~ re_line
      r[:familyname] = $~[1].strip
      r[:firstname] = $~[2].strip
      if r[:firstname].ends_with? " dob" or r[:firstname].ends_with? " DOB"
        r[:firstname] = r[:firstname][0..-5]
        r[:firstname] = r[:firstname].strip
      end
      r[:dob] = get_date(re_line)
      if /([0-9]+\/?[0-9]* [A-Za-z' ]+), ([A-Za-z' ]+) ([0-9]{4})/ =~ re_line
        r[:address_line] = $1
        r[:town] = $2
        r[:postcode] = $3
      end
      if /medicare: ?([0-9\-\/ ]+)/i =~ file
        r[:medicare] = $1.delete(" -/")
      end
      if /CRN: ?([0-9\-\/ ]+)/i =~ file
        r[:crn] = $1.delete(" -/")
      end
      if /DVA: ?([0-9\-\/a-zA-Z ]+)/i =~ file or /DVA number: ?([0-9\-\/A-Za-z ]+)/i =~ file
        r[:dva] = $1.delete(" -/")
      end
      if /password: ?([0-9a-z]+)/i =~ file
        r[:password] = $1
      end
      if /gender: ?([a-z]+)/i =~ file or /sex: ?([a-z]+)/i =~ file
        s = $1.downcase
        if s == "m" or s == "male" or s == "man"
          r[:sex]=1
        elsif s == "f" or s == "female" or s == "woman"
          r[:sex] = 2
        end
      end
      r[:create] = true if /wedgetail create/i =~ file
      r[:discard] = true if /wedgetail discard/i =~ file
    end
    r[:narrative_date] = nil
    [/([0-9]+)\/([0-9]+)\/([0-9]+)/,/([0-9]+)\.([0-9]+)\.([0-9]+)/,/([0-9]+)\-([0-9]+)\-([0-9]+)/].each do |re|
      file.scan(re) do |x|
        day = x[0].to_i
        month = x[1].to_i
        year = x[2].to_i
        if year < 100
          year += 2000
          year -= 100 if year > Date.today.year
        end
        d= Date.civil(year,month,day)
        if d != r[:dob] && (d <= Date.today) && ((! r[:narrative_date] ) || d > r[:narrative_date])
          r[:narrative_date] = d
        end
      end
    end
    r[:narrative_date] = Date.today unless r[:narrative_date]
    return r
  end
      
  # exhaustive matching of a date from a string. Returns Ruby Date type.
  def get_date(datestr)
    datestr.strip!
    raise WedgieError,"Invalid date format" unless 
          /([0-9]+)\/([0-9]+)\/([0-9]+)/ =~ datestr or
          /([0-9]+)\.([0-9]+)\.([0-9]+)/ =~ datestr or
          /([0-9]+)\-([0-9]+)\-([0-9]+)/ =~ datestr
    day = $~[1].to_i
    month = $~[2].to_i
    year = $~[3].to_i
    if year < 100
      year += 2000
      year -= 100 if year > Date.today.year
    end
    Date.civil(year,month,day)
  end

  # runs AbiWord using Kernel#system
  # - +name+ - a suitable filename to create
  # - +file+  - the text of the file
  # - +txt+ - true if you want plaintext as well as HTML
  #
  # returns either html or [html,plaintext], both as strings.
  def self.abiwordise(name,file,txt)
    Tempdir.ensure_tmpdir do
      open(name,'w') {|f| f.write file}
      logger.warn "Starting abiword..."
      Kernel.system("abiword --to=html %s" % name)
      Kernel.system("abiword --to=txt %s" % name) if txt
      name =~ /(.*)\..*/
      file=open("%s.html" % $1){|x| x.read}
      plaintext=open("%s.txt" % $1){|x| x.read} if txt
      logger.warn "Stopping abiword"
      start=file.index('<body>')
      ende=file.index('</body>',start)
      file=file[start+6..ende]
      if txt
        return [file,plaintext]
      else
        return file
      end
    end
  end
end
