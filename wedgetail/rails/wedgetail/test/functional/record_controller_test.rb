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

  fixtures :users, :narratives, :codes

  # Replace this with your real tests.
  def test_nest_without_user
    get :nest
    assert_redirected_to(:action => "login",:controller=>"login")
  end

  def test_nest_with_user
    get :nest, {}, { :user_id => users(:one).id }
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
    assert_select "table#medslist tr:nth-of-type(2) td:first-of-type","risperidone 2mg tab"
  end


  def test_diagnoses
    p = users(:two)
    get :diagnoses,{:wedgetail=>p.wedgetail},{:user_id=>users(:one).id}
    assert_select "table#diagslist tr:nth-of-type(2) td:first-of-type","yellow fever"
  end
end
