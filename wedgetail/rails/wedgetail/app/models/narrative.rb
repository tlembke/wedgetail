require 'date'
require 'tmpdir'
require 'yaml'

class Narrative < ActiveRecord::Base
  belongs_to :patient
  belongs_to :narrative_type
  has_many :outgoing_messages
  has_many :sub_narratives
  belongs_to :condition

  # sets narrative from web upload
  # converts word and RTF documents to HTML before upload
  # uploading via this method does not do patient-name matching
  def uploaded_narrative=(narrative_field)
    # Nothing yet
    name=narrative_field.original_filename
    file=narrative_field
    if narrative_field!=""
      self.content_type=narrative_field.content_type.chomp
      self.content=narrative_field.read
      if content.starts_with?("MSH|") or content.starts_with?("FHS|")
        raise WedgieError,"This interface should not be used to upload HL7 -- use Upload File on the left-hand menu instead"
      end
      convert_docs(name)
    else
      self.content_type="text/x-clinical"
    end    
  end



  def convert_docs(name="noname")
    # this is when someone is manaully associating a Word or RTF file with a patient
    # so we don't need to parse it for a Re: line
    # but we do want to convert to HTML
    case content_type
    when 'application/msword','application/x-msword','application/x-ms-word'
      self.data=self.content
      self.content = MessageProcessor.make_html_from_doc(content)
      self.content_type='text/html'
    when 'application/rtf','application/x-rtf','text/rtf'
      self.content = MessageProcessor.make_html_from_rtf(content)
      self.content_type='text/html'
    when 'image/png','image/jpg','image/gif','application/pdf'
      self.data=content
      self.content_type = content_type
      self.content = name
    end
  end


  # return some form of HTML
  # in particular if we are RTF-inside-PIT the necessary conversion is done
  # Note: does not convert HL7
  def to_html
    case content_type
      when 'text/html'
        content
      when 'text/plain'
        MessageProcessor.make_html_from_text(content)
      when 'application/x-pit'
        c = content.scan(/^301 (.*)$/).join("\n")
        if c.starts_with? "{\\rtf"
          # it's rtf inside PIT
          MessageProcessor.make_html_from_rtf(c)
        else
          MessageProcessor.make_html_from_text(c)
        end
      when 'text/x-clinical'
        c = MessageProcessor.make_html_from_text(content).gsub(/\*(\w+)\*/,"<b>\\1</b>")
        c.gsub(/\{([^\{]+)\}/) do |str|
          obj = Code.get_clinical_object($1,self)
          if obj
            obj.to_html
          else
            str
          end
        end
        else
          MessageProcessor.make_html_from_text(content)
        end
    
  end

  # used to control the message-viewing control.
  # returns +[message,partial]+
  # For HL7 +message+ is the parsed HL7 object, +partial+ is the HL7 message type.
  # For YAML +message+ is the YAML-parsed object (usually a list of hashes) and +partial+ is based on the narrative type
  # For all others +message+ is the HTML and +partial+ is the string "pit"
  def convert
    begin
      if content_type == 'application/edi-hl7'
        message = HL7::Message.parse(self.content)
        partial = message.msh.message_type.message_code.downcase
        if partial.blank?
          # bad, very bad....
          partial = 'pit'
          message = 'Parsing error - HL7 has no MSH segment'
        end
      elsif content_type=='text/yaml'
        message = YAML.load(content)
        if narrative_type_id == 10
          partial = "yaml_form"
        elsif narrative_type_id == 11
          partial = "yaml_script"
	elsif narrative_type_id == 12
          partial = "diagnoseslist"
        elsif narrative_type_id == 2
          partial = "medslist"
        else
          raise "cannot determine partial for yaml narrative type %s" % content_type_id
        end
      elsif content_type=='application/pdf' or content_type=='image/jpg' or content_type=='image/png' or content_type=='image/gif' 
        partial = 'file'
      else
        message = to_html
        partial = 'pit'
      end
    rescue HL7::Error
      # this should hardly happen as the message will have been parsed successfully
      # once to get into the DB
      partial= 'pit'
      message = "Parsing error of HL7 - %s" % $!.to_s
    end
    return [message,partial]
  end
  
  # return the user of the wedgetail of this message
  # (remember all patients have a user entry too)
  def user
    logger.warn("DEBUG: getting user for %p" % self.wedgetail)
    User.find_by_wedgetail(self.wedgetail,:order=>"created_at desc")
  end 
  
  def author
    author_name=""
    if @author=User.find_by_wedgetail(self.created_by,:order=>"created_at desc")
      author_name=@author.full_name
      user_team=User.find_by_wedgetail(@author.team)
      if user_team
          author_name+=", " if author_name!="" and user_team.family_name !=""
          author_name+= user_team.family_name
      end
      if @author.craft and ! @author.craft.name.blank?
        author_name+=" - "+@author.craft.name
      end
    end
    return author_name
  end
  
  def team
    author.team
  end
  
  # send out copies acording to subscription control table.
  def sendout
    # do tricky HL7 and PIT stuff with narrative
    for recipient in self.user.interested_parties
      if recipient.wedgetail != created_by # don't sent back to original sender
        # do tricky encryption and email stuff for recipient
        om = OutgoingMessage.new(:recipient_id=>recipient.wedgetail)
        self.outgoing_messages << om
        om.sendout recipient
        om.save!
      end
    end
  end
  

  # return the PDF object for this narrative
  # NB can_print? had better be true 
  def printout
    raise WedgieError, "can't print #{content_type}" unless content_type == 'text/x-clinical'
    pdf = FPDF.new('P','mm','A4')
    pdf.SetFont('Arial','',10)
    clinical_objects.each do |obj|
      pdf.AddPage
      obj.gen_pdf(pdf)
    end
    return pdf
  end


  # true if something to print in this narrative
  def can_print?
    ret = false
    if content_type == 'text/x-clinical'
      clinical_objects(true).each do |obj|
        ret = true if obj.can_print?
        ''
      end
    end
    return ret
  end

  # get list of clinical objects
  def clinical_objects(exc=false)
    return [] if content_type != 'text/x-clinical'
    objs = []
    content.gsub(/\{([^\{]+)\}/m) do |s|
      obj = Code.get_clinical_object($1,self)
      if obj.nil?
        if exc
          raise WedgieError,"#{$1} is not a valid clinical command" unless obj
        else  # don't raise exception if it's invalid -- it's too late now
          logger.warn("unable to turn #{$1} into a clinical object")
        end
      else
        objs << obj
      end
      ''
    end
    return objs
  end

  # generate outgoing HL7.
  # For HL7 messages this is simply the message itself as a parsed HL7::Message object.
  # for all others a suitable HL7 wrapper is created "ex nihilo"
  def make_outgoing_hl7
    case content_type
    when 'application/edi-hl7'
      hl7 = HL7::Message.parse(content)
    when 'application/x-pit'
      txt = content.scan(/^301 (.*)$/).join("\n")
      if txt.starts_with? "{\\rtf"
        # it's rtf inside PIT
        html, txt= MessageProcessor.make_html_text_from_rtf(txt)
      end
      hl7 = make_hl7_from_text txt
    when 'text/plain','text/x-clinical'
      hl7 = make_hl7_from_text content
    when 'text/html'
      hl7 = make_hl7_from_text plaintext
    end
    return hl7
  end
  
  # make a HL7 message from whole cloth to wrap a non-HL7 message
  def make_hl7_from_text(text)
    hl7 = HL7::Message.new
    msh = hl7.standard_msh
    msh.sending_facility = {:namespace_id=>Pref.namespace_id,:universal_id=>Pref.hostname,:universal_id_type=>"DNS"}
    if ENV['RAILS_ENV'] == 'development'
      pro_id = 'D'
    else
      pro_id = 'P'
    end
    msh.processing_id = {:processing_id=>pro_id}
    hl7 << msh
    p = User.find_by_wedgetail(wedgetail,:order=>"created_at DESC")
    hl7 << p.make_pid
    obr = HL7::Obr.new
    obr[0] = "OBR"
    obr.set_id = 1
    obr.filler_order_number= {:entity_identifier=>"%X" % self.id,:namespace_id=>Pref.namespace_id,:universal_id=>Pref.hostname,:universal_id_type=>"DNS"}
    author = User.find_by_wedgetail(created_by,:order=>"created_at DESC")
    obr.principal_result_interpreter = {:name=>{:family_name=>author.family_name.upcase,:given_name=>author.given_names.upcase,:id_number=>author.id}}
    obr.observation_time = created_at
    usi = {:name_of_coding_system=>"LN"} # LOINC
    message_type = {:message_code=>'REF',:trigger_event=>'I12'}
    case narrative_type_id
    when 1 # Health Summary
      usi[:identifier] = "34133-9"
      usi[:text] = "Summarization of episode note"
    when 2 # Medication Chart
      usi[:identifier] = "19009-0"
      usi[:text] = "Medication.current"
    when 3 # Discharge Summary
      usi[:identifier] = "28574-2"
      usi[:text] = "Discharge note"
    when 4 # Progress Note
      usi[:identifier] = "11488-4"
      usi[:text] = "Consultation Note"
    when 5 # Allergies
      usi[:identifier] = "11488-4" # no good loinc code
      usi[:text] = "Consultation Note"
    when 6 # Scrapbook
      usi[:identifier] = "11488-4"
      usi[:text] = "Consultation Note"
    when 7 # Result
      usi[:identifier] = "11526-1"
      usi[:text] = "Study report"
      message_type = {:message_code=>'ORU',:trigger_event=>'R01'}
    when 8 # Letter
      usi[:identifier] = "34140-4"
      usi[:text] = "Transfer of care referral note"
    when 9 # Immunisations
      usi[:identifier] = "11369-6"
      usi[:text] = "History of immunization"
    else
      usi[:identifier] = "11488-4"
      usi[:text] = "Consultation Note"
    end
    obr.universal_service_identifier = usi
    msh.message_type = message_type
    hl7 << obr
    obx = HL7::Obx.new
    obx[0] = "OBX"
    obx.set_id = 1
    obx.value_type = "FT"
    obx.identifier = usi
    obx.value = text
    obx.result_status = "F"
    hl7 << obx
    hl7
  end
  
  def self.add_post_to_wall(patient,user,content,condition=0)
    @narrative = Narrative.new(:wedgetail=>patient,:created_by=>user,:content=>content,:narrative_type_id=>17,:condition_id=>condition)
    @narrative.narrative_date=Date.today.to_s
    @narrative.save
  end
end
