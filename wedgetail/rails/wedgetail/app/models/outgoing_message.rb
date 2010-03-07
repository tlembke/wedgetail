# outgoing messages sent using the subscription system


# status has the following meanings
# 0..99 number of resends
# 100 max resends reached without an ACK (so failed delivery)
# 200 ACK received
# 300 don't resend: plain notification e-mail sent
# 400 don't resend: booked for download via API
# 500 don't resend: fatal error when trying to send e-mail

class OutgoingMessage < ActiveRecord::Base
  belongs_to :narrative
  
  # send out a message once instance created
  def sendout(recip=nil,max_sends=nil)
    max_sends ||= Pref.max_sends
    recip ||= recipient
    unless recip.team.blank? or recip.team == "0"
      recip = User.find_by_wedgetail(recip.team)
    end
    begin
      case recip.crypto_pref
      when 1 # S/MIME
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        WedgeMailer.crypto_deliver(self.id,hl7.to_hl7,'application/edi-hl7',:x509,recip.email,recip.cert)
      when 2 # OpenPGP
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        WedgeMailer.crypto_deliver(self.id,hl7.to_hl7,'application/edi-hl7',:pgp,recip.email)
      when 3 # e-mail - no crypto
        WedgeMailer.deliver_notify(recip)
        self.status = 300 # don't expect ACKs
      when 4 # direct download
        self.status = 400 # booked for download
      when 5 # unencrypted HL7 - TESTING ONLY
        hl7 = narrative.make_outgoing_hl7
        hl7.msh.message_control_id = "%X" % self.id
        f = open("/home/ian/test_wedgie.hl7","w")
        f.write hl7.to_hl7
        f.close
        WedgeMailer.crypto_deliver(narrative.id,hl7.to_hl7,'application/edi-hl7',:none,recip.email)
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
  
  def recipient
    User.find_by_wedgetail(recipient_id,:order=>"created_at desc")
  end

  def acked(hl7)
    self.status = 200
    self.acked_at = Time.now
    self.acktype = hl7.msa.code
    self.ack = hl7.to_hl7
  end

  def self.check_view(recip,narr)
    # checks if a viewed message is awaiting download by that user
    # checks it off if it is
    om = OutgoingMessage.find(:first,:conditions=>{:recipient_id=>recip.wedgetail,:narrative_id=>narr.id,:status=>300})
    if om
      om.status = 301
      om.acked_at = Time.now
      om.save!
    end
  end

  def status_line
    if status == 0
      "not yet sent"
    elsif status > 0 and status < 100
      "sent #{status} times, last on #{last_sent.to_s}"
    elsif status == 100
      "sending failed; no ACK received"
    elsif status == 200
      "received on #{acked_at.to_s} with HL7 code #{acktype}"
    elsif status == 500
      "ERROR: #{ack}"
    elsif status == 300
      "notified by plain e-mail, waiting for download"
    elsif status == 301
      "viewed on #{acked_at.to_s}"
    elsif status == 400
      "booked for direct download"
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

  def self.force_sendout(recip,narr_id)
    u = User.find_by_username(recip)
    om = OutgoingMessage.find(:first,:conditions=>{:recipient_id=>u.wedgetail,:narrative_id=>narr_id})
    unless om
      om = OutgoingMessage.new({:recipient_id=>u.wedgetail,:narrative_id=>narr_id})
      om.save!
    end
    om.sendout
    om.save!
  end
end
