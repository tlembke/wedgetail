require File.dirname(__FILE__) + '/../test_helper'
require 'entry_controller'

# Re-raise errors caught by the controller.
class EntryController; def rescue_action(e) raise e end; end

class EntryControllerTest < Test::Unit::TestCase
  fixtures :narratives
  fixtures :users
  fixtures :interests
  
  def setup
    @controller = EntryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = narratives(:first).id
    @user=users(:one)
  end


  def test_new
    get :new,{},{:user_id=>@user.id}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:narrative)
  end

  def test_create
    num_narratives = Narrative.count

    post :create, {:narrative =>  
      {:wedgetail=>"1234",
      :narrative_type_id=>1,
      :title=>"Test Narrative",
      :uploaded_narrative=>fixture_file_upload("letter.txt","text/plain")}
    },{:user_id=>@user.id}

    assert_response :redirect
    assert_redirected_to :action => 'show'

    assert_equal num_narratives + 1, Narrative.count
  end

  
  def test_upload
    user = users(:one)
    letter = <<EOF
Dear Wedgetail

This is a test message to check web upload and forwarding
of messages.

Re: Bloggs, Jack, DOB 2/1/1960

Yours sincerely,

Unit Test Script
EOF
    post(:upload,{:upload=>{:text=>letter}},{:user_id=>user.id})
    assert_equal "File successfully uploaded", flash[:notice]
  end

  def test_upload2
    user = users(:one)
    post(:upload,{:upload=>{:file=>fixture_file_upload("letter.txt","text/plain")}},{:user_id=>user.id})
    assert_equal "File successfully uploaded", flash[:notice]
  end

  def test_upload_hl7
    user = users(:one)
    post(:upload,{:upload=>{:file=>fixture_file_upload("potter.hl7","text/plain")}},{:user_id=>user.id})
    assert_equal "File successfully uploaded", flash[:notice]
  end
end
