require File.dirname(__FILE__) + '/../test_helper'
require 'conditions_controller'

# Re-raise errors caught by the controller.
class ConditionsController; def rescue_action(e) raise e end; end

class ConditionsControllerTest < Test::Unit::TestCase
  fixtures :conditions

  def setup
    @controller = ConditionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:conditions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_condition
    old_count = Condition.count
    post :create, :condition => { }
    assert_equal old_count+1, Condition.count
    
    assert_redirected_to condition_path(assigns(:condition))
  end

  def test_should_show_condition
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_condition
    put :update, :id => 1, :condition => { }
    assert_redirected_to condition_path(assigns(:condition))
  end
  
  def test_should_destroy_condition
    old_count = Condition.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Condition.count
    
    assert_redirected_to conditions_path
  end
end
