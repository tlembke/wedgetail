require File.dirname(__FILE__) + '/../test_helper'
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end

class MessagesControllerTest < Test::Unit::TestCase
  fixtures :messages,:users

  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @session = {:user_id=>users(:one)}
    @first_id = messages(:one).id
  end

  def test_index
    get :index,{},@session
    assert_response :success
    assert_template 'messages/index'
  end

  def test_show
    get :show,{:id => @first_id},@session

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:message)
    assert assigns(:message).valid?
  end

  def test_new
    get(:new,{},@session)

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:message)
  end

 def test_new_with_id
    get(:new,{:id=>"12346"},@session)

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:message)
  end



  def test_create
    num_messages = Message.count

    post :create,{:message => {:recipient_id=>"12346"}},@session

    assert_response :redirect
    assert_redirected_to :action => 'index'

    assert_equal num_messages + 1, Message.count
  end

  def test_update
    post(:update, {:id => @first_id}, @session)
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Message.find(@first_id)
    }

    post(:destroy,{:id => @first_id},@session)
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Message.find(@first_id)
    }
  end
end
