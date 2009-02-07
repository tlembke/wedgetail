require File.dirname(__FILE__) + '/../test_helper'

class WedgeMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting
  fixtures :users,:prefs,:narratives,:codes
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  def test_notify
    @expected.subject = 'New Wedgetail Message'
    @expected.body    = read_fixture('notify')
    @expected.to = users(:one).email
    @expected.from = "Wedgetail <wedge@medicine.net.au>"
    @expected['Auto-Submitted'] = 'auto-generated'
    @expected.date    = Time.now
    assert_equal @expected.encoded, WedgeMailer.create_notify(users(:one)).encoded
  end

  def test_receive
    text = <<eom
Re: Potter, Harry, dob: 11/8/1994

This is a unit test message
eom
    m = WedgeMailer.crypto_deliver(1,text,"text/plain",:x509,"ihaywood@iinet.net.au")
    WedgeMailer.receive(m.encoded)
    n = Narrative.find_by_wedgetail(users(:harry).wedgetail)
    assert /unit test/ =~ n.content
  end
      
  def test_send
    m = WedgeMailer.crypto_deliver(1,"This is a an example message","text/plain",:x509,"ihaywood@iinet.net.au")
    assert m
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/wedge_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
