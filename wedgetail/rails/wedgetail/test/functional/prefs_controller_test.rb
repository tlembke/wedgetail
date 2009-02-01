require File.dirname(__FILE__) + '/../test_helper'
require 'prefs_controller'

# Re-raise errors caught by the controller.
class PrefsController; def rescue_action(e) raise e end; end

class PrefsControllerTest < Test::Unit::TestCase
  fixtures :prefs,:users

  def setup
    @controller = PrefsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @session = {:user_id=>users(:one)}
  end

  def test_index
    get :index,{},@session
    assert_response :success
    assert_template 'show'
  end


  def test_show
    get :show,{},@session
    assert_response :success
    assert_template 'show'
  end


  def test_edit
    get :edit,{},@session
    assert_response :success
    assert_template 'edit'
  end

  def test_update
    assert true
  end
end
