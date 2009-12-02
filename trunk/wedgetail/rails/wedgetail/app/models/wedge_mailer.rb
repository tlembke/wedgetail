require 'base64'
require "open3"
begin
  require "gpgme"
rescue LoadError
end
include Open3

# the main wedgetail mail handler
class WedgeMailer < ActionMailer::Base

  # notify a recipient of a new wedgetail message (does not contain the message)
  def notify(recipient)
    subject    'New Wedgetail Message'
    body       "recipient"=> recipient, "host"=>Pref.host_url
    # body        :host=>request.host #:host => request.host
    recipients  recipient.email
    from        Pref.email
    sent_on    Time.now
    #headers    'Auto-Submitted'=>'auto-generated' # RFC 3834

  end
  
  def result_notify(recipient)
    subject    'New Wedgetail Result'
    body       "recipient"=> recipient, "host"=>Pref.host_url
    # body        :host=>request.host #:host => request.host
    recipients  recipient.email
    from        Pref.email
    sent_on     Time.now
    #headers    'Auto-Submitted'=>'auto-generated' # RFC 3834

  end
  
  # error report to the wedgemail developer (Ian Haywood)
  def message_error(email,hl7,error)
    @subject = "Wedgetail Got Wedgied"
    @recipients = ['Ian Haywood <ihaywood@iinet.net.au>']
    @from = Pref.email
    part :content_type => "text/plain",:body=>error
    if hl7
      attachment :content_type => "text/plain",
                :body=> hl7.to_s,
                :filename=> "hl7.txt"
    else
      attachment  :content_type => "message/rfc822",
                  :body => email.encoded,
                  :filename =>"email"
    end
  end
  
  # human-readable acknowledgement message
  def human_ack(email)
    @subject    = 'Wedgetail has recieved your message'
    @body["date"]       = email.date
    @recipients = email.from
    @from       = Pref.email
    @sent_on    = Time.now
    @headers    = {'Auto-Submitted'=>'auto-replied'} # RFC 3834
  end
  
  # human-readable negative acknowledgement
  def human_nack(email,error)
    @subject    = 'ERROR: Wedgetail could not process your message'
    @body["date"]       = email.date
    @body["error"] = error
    @recipients = email.from
    @from       = Pref.email
    @sent_on    = Time.now
    @headers    = {'Auto-Submitted'=>'auto-replied'}
  end
  
  # receiver for new messages
  def receive(email)
    begin
      h = handle(email,nil)
      logger.debug "ultimate error: %p" % h[:error]
      m = nil
      id = nil
      return if email['Auto-Submitted'] =~ /auto-.*/ # don't process further if auto-generated, to avoid mail loop
      if h[:error]
        WedgeMailer.deliver_message_error(email,h[:hl7],h[:error]) # tell me about it
        if h[:hl7]
          m = h[:hl7].ack(h[:error]) # HL7 error ACK
          m.msh.sending_facility = {:namespace_id=>Pref.namespace_id,:universal_id=>Pref.hostname,:universal_id_type=>"DNS"}
          m = m.to_hl7
          mime = 'application/edi-hl7'
          subject = '[wedgetail] HL7 message'
        else
          mime= 'text/plain'
          m = <<EOF
Your message to wedgetail on #{email.date.to_s}, could not be
sent due to #{h[:error]}
EOF
          subject= '[wedgetail] ERROR'
        end
      elsif h[:mp]
        # no error, so we succeeded
        h[:mp].save
        if h[:hl7]
          m = h[:mp].form_hl7_response(h[:hl7])
          id = h[:mp].get_id
          m = m.to_hl7 unless m.blank?
          logger.debug "ACK to be sent: %p" % m
          mime = 'application/edi-hl7'
          subject = '[wedgetail] HL7 message'
        else
          mime = 'text/plain'
          m = <<EOF
Your message to wedgetail on #{email.date.to_s}
was processed successfully.
EOF
          subject = '[wedgetail] message received'
        end
      end
      if m: # if we have reply to send
        # get plain sender's e-mail (for finding keys)
        addr = email.from_addrs
        addr = addr[0] if addr.respond_to? :length
        addr = addr.spec
        logger.debug "senders address computed to be %p" % addr
        if h[:cert].respond_to? :fpr
          crypto_mode = :pgp
        elsif h[:cert]
          crypto_mode = :x509
        else
          crypto_mode = :none
        end
        # FIXME: for now ignore crypto_mode and always send unencrypted as we are testing argus
        id = Time.now unless id 
        crypto_deliver(id,m,mime,:none,addr,subject,'auto-replied')
      end
    rescue
      # log uncaught expceptions
      logger.error $!.message
      logger.error $!.backtrace.join("\n")
      raise
    end
  end
  
  # deliver a message securely
  # - +text+ the contents of the message
  # - +mime+ - string, its MIME-type
  # - +crypto_mode+, one of the symbols :x509, :pgp, and :none
  # - +to+ recipients e-mail address, used to find encrypting key
  # - +subject+ the message subject (Note: this doesn't get encrypted)
  # - +auto_mode+ - contents of the Auto-Submitted: RFC838 header
  def self.crypto_deliver(id,text,mime,crypto_mode,to,cert=nil,subject='[wedgetail] message',auto_mode='auto-generated')
    new.crypto_deliver(id,text,mime,crypto_mode,to,cert,subject,auto_mode)
  end
  
  def crypto_deliver(id,text,mime,crypto_mode,to,cert=nil,subject='[wedgetail] message',auto_mode='auto-generated')
    logger.debug "sending message %p" % text
    cert ||= to
    # form EDI packet as per HL7 docs
    b64 = Base64.encode64(text)
    b64.gsub!("\n","\r\n")
    case mime
      when 'text/plain','text/x-clinical'
      fname = 'W%.7X.txt'
      when 'application/edi-hl7'
      fname = 'W%.7X.hl7'
      else
      fname = 'W%.7X.dat'
      end
    fname = fname % id
    mail_out = "Content-Type: application/octet-stream;name=\"#{fname}\"\r\nContent-Transfer-Encoding: base64\r\nContent-Disposition: ATTACHMENT; filename=\"#{fname}\"\r\n\r\n#{b64}"
    # use appropriate crypto based on what we got
    case crypto_mode
    when :pgp
      mail_out = pgp_create(mail_out,to)
    when :x509
      mail_out = x509_create(mail_out,cert)
    else
      logger.info "forming unencrypted message"
      mail_out = TMail::Mail.parse(mail_out)
    end
    # send the message
    mail_out.subject = subject
    mail_out.to = to
    mail_out.from = Pref.email
    mail_out.date = Time.now
    mail_out['Auto-Submitted'] = auto_mode
    WedgeMailer.deliver(mail_out)
    return mail_out
  end

  # deliver mail as encrypted X.509
  # - +m+ message as a string
  # - +to+ addressee to find encryption key
  def x509_create(m,to)
    result = result2 = err = ''
    cmd = "openssl smime -sign -inkey %s -passin pass:Pass-123 -signer %s" % [RAILS_ROOT+"/certs/wedgie_sign.key",RAILS_ROOT+"/certs/wedgie_sign.pem"]
    logger.debug "CMD: %s" % cmd
    popen3(cmd) do |stdin, stdout, stderr|
      stdin.write(m)
      stdin.close
      result = stdout.read
      err = stderr.read
    end
    unless result.length > 0
      logger.info "signing error: %p" % err
      raise WedgieError, err
    end
    f = RAILS_ROOT+'/certs/'+to
    unless File.exists? f
      raise WedgieError, "I don't have a certificate for %s" % to
    end
    cmd = "openssl smime -encrypt %s" % f
    logger.debug "CMD: %s" % cmd
    popen3(cmd) do |stdin, stdout, stderr|
      stdin.write(result)
      stdin.close
      result2 = stdout.read
      err = stderr.read
    end
    unless result2.length > 0 
      logger.error "encryption error: %s" % err
      raise WedgieError, err
    end
    TMail::Mail.parse(result2)
  end
  
  # deliver a mail as encrypted OpenPGP format
  # - +m+ mail as string
  # - +to+ addressess must uniquely match a UID of a key on the keyring
  def pgp_create(m,to)
    gpg = GPGME.sign(m,{:armor=>true,:mode=>GPGME::SIG_MODE_DETACH})
    gpg.gsub!("\n","\r\n")
    boundary = Base64.encode64(Time.now.to_s).strip
    boundary1 = "inner"+boundary
    m2 = <<EOF
Content-Type: multipart/signed;\r
  boundary="#{boundary1}";\r
  protocol="application/pgp-signature";\r
  micalg=pgp-sha1\r
\r
--#{boundary1}\r
#{m}\r
--#{boundary1}\r
Content-Type: application/pgp-signature; name=signature.asc\r
Content-Description: This is a digitally signed message part.\r
\r
#{gpg}\r
--#{boundary1}--\r
EOF
    logger.info "PGP-encrypting to %s" % to
    logger.info "*** encrypting ***"
    logger.info m2
    gpg = GPGME.encrypt([to],m2,:armor=>true)
    gpg.gsub!("\n","\r\n")
    m3 = TMail::Mail.new
    boundary2 = "outer"+boundary
    m3.body = <<EOF
--#{boundary2}\r
Content-Type: application/pgp-encrypted\r
Content-Disposition: attachment\r
\r
Version: 1\r
--#{boundary2}\r
Content-Type: application/octet-stream\r
Content-Disposition: inline; filename="msg.asc"\r
\r
#{gpg}\r
--#{boundary2}--\r
EOF
    m3.set_content_type('multipart','encrypted',{'boundary'=>boundary2,'protocol'=>'application/pgp-encrypted'})
    m3
  end
  
  # recursive, handle a message's MIME components
  # returns a Hash of max 3 keys: :error is nil if no error, :hl7 which is nil if HL7 not involved, :cert which is nil if no crypto
  def handle(email,cert=nil)
    if email.multipart?
      error=nil
      pgp=false
      possible_pgp=''
      h=nil
      email.parts.each do |e|
        if e.content_type == 'application/octet-stream'
          possible_pgp = e.body
        end
        if e.content_type == 'application/pgp-encrypted'
          pgp = true
        end
        h = handle(e,cert)
        if ! h[:error] # i.e. if we succeeded, return directly, otherwise, keep trying
          return h
        end
      end
      if pgp
        return handle_pgp(possible_pgp)
      else
        return h
      end
    else
      ct = MessageProcessor.detect_type(email.body,email.content_type,"")
      logger.info "detected type %p" % ct
      if ct=='application/edi-hl7'
        # we have HL7
        begin
          msg = HL7::Message.parse(email.body)
          begin
            mp = MessageProcessor.new(logger,user_from_cert(cert),msg,ct,nil)
            return {:hl7=>msg,:mp=>mp,:cert=>cert}
          rescue WedgieError
            return {:error=>$!.to_s,:hl7=>msg,:cert=>cert}
          end
        rescue WedgieError
          return {:error=>"HL7 parse error: %s" % $!.to_s,:cert=>cert}
        end
      elsif ct=='application/x-openpgp'
        logger.info 'Extracting from inline PGP'
        a = email.body =~ /-----BEGIN PGP MESSAGE-----/
        b = (email.body =~ /-----END PGP MESSAGE-----/)+25
        return handle_pgp(email.body[a..b])
      elsif ct=='application/x-pkcs7-mime'
        # it's encrypted X.509. Deep breath..
        result = ''
        err = ''
        m = nil
        cert = nil
        file = RAILS_ROOT+"/certs/wedgie_decrypt.key"
        cert = RAILS_ROOT+"/certs/fac_encrypt.pem"
        open(file).read
        cmd = "openssl smime -decrypt -inkey %s -passin pass:Pass-123" % file
        logger.debug "CMD: %s" % cmd
        popen3(cmd) do |stdin, stdout, stderr|
          begin
            stdin.write(email.port)
            stdin.close
          rescue Errno::EPIPE
          end
          result = stdout.read
          err = stderr.read
        end
        unless $?.success? and err.blank?
          logger.info "decryption error: %s" % err
          return {:error=>err}
        end
        logger.info "OpenSSL decryption succeeded"
        # result should be a signed block
        result2 = ''
        certsdir = RAILS_ROOT+"/certs"
        outcert = Tempdir.tmpdir+"cert.pem"
        cmd = "openssl smime -verify -signer %s -CApath %s" % [outcert,certsdir]
        logger.debug "CMD: %s" % cmd
        popen3(cmd) do |stdin, stdout, stderr|
          stdin.write(result)
          stdin.close
          result2 = stdout.read
          err = stderr.read
        end
        if result2.length < 20
          logger.debug("OpenSSL verification give clearly invalid data: %p" % result2)
          return {:error=>err}
        end
        logger.info "OpenSSL verification succeeded"
        logger.info "*****Verified doc*****"
        logger.info result2
        # result now *should* contain a MIME packet...
        begin
          m = TMail::Mail.parse(result2)
        rescue TMail::SyntaxError
          # ...or not, use the actual text itself as the body of a fake MIME packet
          m = TMail::Mail.new
          m.body = result2
          m.content_type=  'application/octet-stream'
        end
        # examine the signer's certificate
        cmd = 'openssl x509 -in %s -text' % outcert
        logger.debug "CMD: %s" % cmd
        cert = IO.popen(cmd) {|x| x.read}
        cert ||= ""
        # recur with decrypted text
        h = handle(m,cert)
        h[:error] = err unless err =~ /^Verification successful/
        h[:error]="Could not load OpenSSL certificate" unless cert.length > 0 
        return h
      elsif ct
        begin 
          mp = MessageProcessor.new(logger,user_from_cert(cert),email.body,ct,nil)
          return {:mp=>mp,:cert=>cert}
        rescue WedgieError
          return {:error=>$!.to_s,:cert=>cert}
        end
      else
        return {:error=>"message did not have a valid MIME type",:cert=>cert}
      end
    end
  end

  # turn a certificate into a user number
  def user_from_cert(cert)
    if cert.respond_to? :fpr
      return user_from_pgp(cert)
    else
      return user_from_x509(cert)
    end
  end
  
  # infer the user from the e-mail embeds in an X.509 cert
  # returns a User ID object
  def user_from_x509(cert)
    return 1 unless (cert =~ /email:(.*)/ or cert =~ /emailAddress=([a-zA-Z0-9\.]+@[a-zA-Z0-9\.]+)/) # default to Big Wedgie
    logger.debug "extracted email %s from X.509 certificate " % $1
    u=User.find(:first,:conditions=>["role < 7 and email=? or cert=?",$1,$1],:order => "role DESC")
    raise WedgieError,"No such user with e-mail %s" % $1 if u.nil?
    logger.info "mapped to user %s" % u
    # save the cert so we can send to this user in the future
    #f = open(RAILS_ROOT+"/certs/"+email,"w")
    #f.write cert
    #f.close
    return u.id
  end
  
  # infer user from e-mail UIDs on a OpenPGP key. Checks each UID and returns the
  # first one that matches.
  def user_from_pgp(sig)
    ctx = GPGME::Ctx.new
    if from_key = ctx.get_key(sig.fingerprint)
      logger.debug "found GPG key fingerprint %s" % sig.fingerprint
      u = nil
      from_key.uids.each do |uid|
        logger.debug "checking GnuPG key ID %p" % uid
        u ||= User.find_by_email(uid.email)
      end
      raise WedgieError,"No user found using PGP sig %s" % sig.to_s if u.nil?
      return u.id
    else
      raise WedgieError,"Signature %s doesn't seem to have a UID available" % sig.to_s
    end
  end
  
  # handle a OpenPGP-encrypted MIME component
  def handle_pgp(pgp)
    begin
      logger.info "found OpenPGP data, decrypting...."
      plain = StringIO.new("","w")
      cert = GPGME.decrypt(pgp,plain) {|s| s}
      logger.debug "cert is %p" % cert
      logger.debug "message is %p" % plain.string
      m = nil
      begin 
        m = TMail::Mail.parse(plain.string)
        if cert.nil? and m.multipart?
          # uh-oh: KMail-style detached signature
          logger.debug "Assuming PGP-MIME detached signature"
          logger.debug "first MIME part is %p" % (text = m.parts[0].body)
          logger.debug "second MIME part is %p" % (sig = m.parts[1].body)
          ctx = GPGME::Ctx.new
          d1 = GPGME.input_data(sig)
          d2 = GPGME.input_data(text)
          ctx.verify(d1,d2,nil)
          sigs = ctx.verify_result.signatures
          if sigs.length == 0
            return {:error=>'Unable to get valid signatures on message'}
          end
          cert = sigs[0]
          m = m.parts[0]
        end
      rescue TMail::SyntaxError
        # ...or not, use the actual text itself as the body of a fake MIME packet
        m = TMail::Mail.new
        m.body = text
        m.content_type= 'application/octet-stream'
      end
      logger.info "cert is null -- GnuPG without signature" unless cert
      h = handle(m,cert) # process here as we want the hl7 object even if signature error
      if cert
        case i = GPGME::gpgme_err_code(cert.status)
        when GPGME::GPGME_SIG_STAT_NOSIG
          h[:error] = 'no valid signature found (STAT_NOSIG)'
        when GPGME::GPGME_SIG_STAT_NONE
          h[:error] = 'no valid signature found (STAT_NONE)'
        when GPGME::GPGME_SIG_STAT_NOKEY
          h[:error] = 'no valid signature found (STAT_NOKEY)'
        when GPGME::GPGME_SIG_STAT_GOOD
          logger.debug 'Good signature'
        when GPGME::GPGME_SIG_STAT_BAD
          h[:error] = 'bad signature'
        when GPGME::GPGME_SIG_STAT_ERROR
          h[:error] = 'unable to check signature (STAT_ERROR)'
        when GPGME::GPGME_SIG_STAT_GOOD_EXP
          h[:error] = 'signature good, but expired'
        when GPGME::GPGME_SIG_STAT_GOOD_EXPKEY
          #h[:error] = 'signature good, but key expired'
          #GPGME reports this even when I know key is valid, so just log it
          logger.debug('key %s listed as expired' % cert.fpr)
        when GPGME::GPGME_SIG_STAT_DIFF
          h[:error] = 'signature not valid (STAT_DIFF)'
        else
          h[:error] = 'unknown signature status code %s' % i
        end
      end
      return h
    rescue GPGME::Error
      return {:error=>$!}
    end
  end
end
