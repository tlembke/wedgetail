require File.dirname(__FILE__) + '/../test_helper'
require 'prefs_controller'

# Re-raise errors caught by the controller.
class PrefsController; def rescue_action(e) raise e end; end

class PrefsControllerTest < Test::Unit::TestCase
  fixtures :prefs

  def setup
    @controller = PrefsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = prefs(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:prefs)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:pref)
    assert assigns(:pref).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:pref)
  end

  def test_create
    num_prefs = Pref.count

    post :create, :pref => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_prefs + 1, Pref.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:pref)
    assert assigns(:pref).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Pref.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Pref.find(@first_id)
    }
  end
end
