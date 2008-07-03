require File.dirname(__FILE__) + '/../test_helper'
require 'consultations_controller'

# Re-raise errors caught by the controller.
class ConsultationsController; def rescue_action(e) raise e end; end

class ConsultationsControllerTest < Test::Unit::TestCase
  fixtures :consultations

  def setup
    @controller = ConsultationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:consultations)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_consultation
    old_count = Consultation.count
    post :create, :consultation => { }
    assert_equal old_count+1, Consultation.count
    
    assert_redirected_to consultation_path(assigns(:consultation))
  end

  def test_should_show_consultation
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_consultation
    put :update, :id => 1, :consultation => { }
    assert_redirected_to consultation_path(assigns(:consultation))
  end
  
  def test_should_destroy_consultation
    old_count = Consultation.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Consultation.count
    
    assert_redirected_to consultations_path
  end
end
