require File.dirname(__FILE__) + '/../test_helper'
require 'boomerang_controller'

# Re-raise errors caught by the controller.
class BoomerangController; def rescue_action(e) raise e end; end

class BoomerangControllerTest < Test::Unit::TestCase
  def setup
    @controller = BoomerangController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
