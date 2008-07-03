require 'date'
require 'tmpdir'
require 'yaml'

class Narrative < ActiveRecord::Base
  belongs_to :patient
  belongs_to :narrative_type
  has_many :outgoing_messages


  # sets narrative from web upload
  # converts word and RTF documents to HTML before upload
  # uploading via this method does not do patient-name matching
  def uploaded_narrative=(narrative_field)
    # Nothing yet
    #name=base_part_of(narrative_field.original_filename)
    if narrative_field!=""
      content_type=narrative_field.content_type.chomp
      content=narrative_field.read
      # this is when someone is manaully associating a Word or RTF file with a patient
      # so we don't need to parse it for a Re: line
      # but we do want to convert to HTML
      case content_type
        when 'application/msword','application/x-msword','application/x-ms-word'
          self.content = MessageProcessor.make_html_from_doc(file)
          self.content_type='text/html'
        when 'application/rtf','application/x-rtf','text/rtf'
          self.content = MessageProcessor.make_html_from_rtf(file)
          self.content_type='text/html'
        else
          self.content = content
          self.content_type = content_type
      end
    else
      self.content_type="text/plain"
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
    end
  end

  def content_yaml
    raise "Narrative is not text/yaml" unless content_type=="text/yaml" 
    YAML::parse self.content
  end

  def content_yaml=(x)
    self.content = x.to_yaml
  end

  # used to control the message-viewing control.
  # returns +[message,partial]+
  # For HL7 +message+ is the parsed HL7 object, +partial+ is the HL7 message type.
  # For all others +message+ is the same as value and +partial+ is the string "pit"
  def convert()
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
        message = content_yaml
	if narrative_type_id == 10
          partial = "form"
        elsif narrative_type_id == 11
          partial = "script"
	elsif narrative_type_id == 12
          partial = "disease"
        else
          raise "cannot determine partial for yaml narrative type %s" % content_type_id
        end
      else
        message = to_html
        partial = 'pit'
      end
    rescue HL7::Error
      # this should hardly happen as the message will have been parsed successfully
      # once to get into the DB
      partial= 'pit'
      message = "Parsing error of HL7"
    end
    return [message,partial]
  end
  
  # return the user of the wedgetail of this message
  # (remember all patients have a user entry too)
  def user
    logger.warn("DEBUG: getting user for %p" % self.wedgetail)
    User.find_by_wedgetail(self.wedgetail)
  end 
  
  def author
    author_name=""
    @author=User.find_by_wedgetail(self.created_by)
    author_name=@author.full_name if @author
    user_team=User.find_by_wedgetail(self.created_team)
    if user_team
      author_name+=", " if author_name!="" and user_team.family_name !=""
      author_name+= user_team.family_name
    end
    return author_name
  end
  
  def team
      user_team=User.find_by_wedgetail(self.created_team)
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
    when 'text/plain'
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
    msh.message_type = {:message_code=>'ORU',:trigger_event=>'R01'}
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
    usi = {:name_of_coding_system=>"LN"} # LOINC
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
end
