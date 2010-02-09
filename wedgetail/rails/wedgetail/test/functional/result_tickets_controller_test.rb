require 'test_helper'

class ResultTicketsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:result_tickets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create result_ticket" do
    assert_difference('ResultTicket.count') do
      post :create, :result_ticket => { }
    end

    assert_redirected_to result_ticket_path(assigns(:result_ticket))
  end

  test "should show result_ticket" do
    get :show, :id => result_tickets(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => result_tickets(:one).to_param
    assert_response :success
  end

  test "should update result_ticket" do
    put :update, :id => result_tickets(:one).to_param, :result_ticket => { }
    assert_redirected_to result_ticket_path(assigns(:result_ticket))
  end

  test "should destroy result_ticket" do
    assert_difference('ResultTicket.count', -1) do
      delete :destroy, :id => result_tickets(:one).to_param
    end

    assert_redirected_to result_tickets_path
  end
end
