require File.dirname(__FILE__) + '/../test_helper'

class CompletionsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def test_javascript_generation
    get :script
    assert_response :success
    assert_template 'script'
  end
end
