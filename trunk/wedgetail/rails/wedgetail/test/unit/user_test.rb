require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "password dictionary check" do
    u = User.new
    u.password = "gallbladder"
    u.password_confirmation = "gallbladder"
    u.wedgetail = "fake"
    u.username = "fake"
    u.role = 0
    assert !u.save,"won't save with dictionary word"
  end
end
