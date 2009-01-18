require File.dirname(__FILE__) + '/../test_helper'

class WedgeMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting
  fixtures :users,:prefs
  
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
    @expected.date    = Time.now
    @expected.to = users(:one).email
    @expected.from = "Wedgetail <wedge@medicine.net.au>"
    @expected['Auto-Submitted'] = 'auto-generated'
    assert_equal @expected.encoded, WedgeMailer.create_notify(users(:one)).encoded
  end

  def test_receive
    Dir.glob("#{FIXTURES_PATH}/wedge_mailer/*.email") do |fname|
      WedgeMailer.receive(open(fname).read)
    end
    n = Narrative.find_by_wedgetail(users(:harry).wedgetail)
    assert /unit test/ =~ n.content
  end
      

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/wedge_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
