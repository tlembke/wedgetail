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

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
