require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  
  def setup
    @controller = LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  fixtures :users
  fixtures :prefs
  
  # Replace this with your real tests.
  def upload_cert(cert)
    user = users(:one)
    post(:load_certificate,{:wedgetail=>user.wedgetail, :certificate_upload=>{:certificate=>fixture_file_upload(cert,"application/octet-stream")}},{:user_id=>user.id})
    assert_redirected_to :controller=>'login',:action=>'edit'
    assert_equal "Certificate Uploaded", flash[:notice]
  end
  
  def test_upload_cert1
    upload_cert "wedge_mailer/ian.cert"
    assert File.exists?("/home/ian/wedgetail/certs/ihaywood@iinet.net.au")
  end

end
