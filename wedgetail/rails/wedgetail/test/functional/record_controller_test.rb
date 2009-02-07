require File.dirname(__FILE__) + '/../test_helper'
require 'record_controller'

# Re-raise errors caught by the controller.
class RecordController; def rescue_action(e) raise e end; end

class RecordControllerTest < Test::Unit::TestCase

  def setup
    @controller = RecordController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  fixtures :users, :narratives, :codes,:audits,:outgoing_messages

  # Replace this with your real tests.
  def test_nest_without_user
    get :nest
    assert_redirected_to(:action => "login",:controller=>"login")
  end

  def test_nest_with_user
    get :nest, {}, { :user_id => users(:one).id }
    assert_response :success
    assert_template 'nest'
    assert_select("tr#wedgetail_1234")
  end

  def test_hatch
    p = users(:two)
    post :hatch,{:wedgetail=>p.wedgetail},{:user_id=>users(:one).id}
    assert_select_rjs("hatch_"+p.wedgetail) do
      assert_select "font","Hatched"
    end
  end

  def test_medications
    p = users(:two)
    get :medications,{:wedgetail=>p.wedgetail},{:user_id=>users(:one).id}
    assert_response :success
    assert_template 'medications'
    assert_select "table#medslist tr:nth-of-type(2) td:first-of-type","risperidone 2mg tab"
  end


  def test_diagnoses
    p = users(:two)
    get :diagnoses,{:wedgetail=>p.wedgetail},{:user_id=>users(:one).id}
    assert_response :success
    assert_template 'diagnoses'
    assert_select "table#diagslist tr:nth-of-type(2) td:first-of-type","yellow fever"
  end

  def test_audit
    p = users(:two)
    get(:audit,{:wedgetail=>p.wedgetail},{:user_id=>users(:one).id})
    assert_response :success
    assert_template 'audit'
    assert_select "td[width=50%]", /Ian Haywood/
  end
   


  def test_outgoings
    p = users(:two)
    narr = narratives(:first)
    get(:outgoings,{:wedgetail=>p.wedgetail,:id=>narr.id},{:user_id=>users(:one).id})
    assert_response :success
    assert_template 'outgoings'
    assert_select "table#om_table tr td:first-of-type",/Ian Haywood/
  end

  def test_create
    post(:create,{:patient=>{"address_line"=>"1 foo", 
             "postcode"=>"1111", 
             "password_confirmation"=>"123", 
             "wedgetail"=>"", 
             "role"=>"", 
             "dob(1i)"=>"2009", 
             "dva"=>"", 
             "dob(2i)"=>"2", 
             "family_name"=>"Blogggs", 
             "sex"=>"1", 
             "dob(3i)"=>"5", 
             "known_as"=>"", 
             "town"=>"foo", 
             "medicare"=>"", 
             "crn"=>"", 
             "password"=>"123", 
             "given_names"=>"Jack", 
             "state"=>"NSW"}},
         {:user_id=>users(:one).id})
    assert_response 302
    newpatient = User.find(:first,:conditions=>{:family_name=>"Blogggs"})
    assert_equal newpatient.hatched,false
  end

  def test_show1
    get :show,{:wedgetail=>'1237'},{:user_id=>users(:one).id}
    assert_template 'unconfirmed'
  end

  def test_show2
    get :show,{:wedgetail=>'1235'},{:user_id=>users(:one).id}
    assert_template 'show'
  end

  def test_consent_form
    get :consent,{:wedgetail=>'1237'},{:user_id=>users(:one).id}
    assert_equal @response.content_type,'application/pdf'
    assert_response :success
  end
end
