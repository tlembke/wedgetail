# otugoing messages sent using the subscription system

class OutgoingMessage < ActiveRecord::Base
  belongs_to :narrative
  
  # send out a message once instance created
  def sendout(recipient=nil,max_sends=nil)
    max_sends ||= Pref.max_sends
    recipient ||= User.find_by_wedgetail(recipient_id)
    unless recipient.team.blank? or recipient.team == "0"
      recipient = User.find_by_wedgetail(recipient.team)
    end
    begin
      case recipient.crypto_pref
      when 1 # S/MIME
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        WedgeMailer.crypto_deliver(hl7.to_hl7,'application/edi-hl7',:x509,recipient.email,recipient.cert)
      when 2 # OpenPGP
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        WedgeMailer.crypto_deliver(hl7.to_hl7,'application/edi-hl7',:pgp,recipient.email)
      when 3 # e-mail - no crypto
        WedgeMailer.deliver_notify(recipient)
        self.status = 300 # don't expect ACKs
      when 4 # direct download
        self.status = 400 # booked for download
      when 5 # unencrypted HL7 - TESTING ONLY
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        f = open("/home/ian/test_wedgie.hl7","w")
        f.write hl7.to_hl7
        f.close
        WedgeMailer.crypto_deliver(hl7.to_hl7,'application/edi-hl7',:none,recipient.email)
      end
      self.last_sent = Time.now
    rescue WedgieError
      self.status = 500
      self.ack = $!.to_str
      self.acktype = 'ERR'
    end
    if status < 100
      self.status += 1
      if status > max_sends # maximum number of sends
        self.status = 100
      end
    end
  end
  
  # resend all outgoing messages which haven't been acknowledged yet
  # should be called via script/runner from +cron+
  def self.resend_acks
    # run from a cron job or similar
    max_sends = Pref.max_sends # pref involves a query, so only do this once
    OutgoingMessage.find(:all,:conditions=>["status < 100"]) do |om|
      if om.last_sent < 1.hours.ago # don't bother if sent in last hour
        om.sendout(nil,max_sends)
        om.save!
      end
    end
  end
end
