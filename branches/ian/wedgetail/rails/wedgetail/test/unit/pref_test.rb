require File.dirname(__FILE__) + '/../test_helper'

class PrefTest < Test::Unit::TestCase
  fixtures :prefs

  # Replace this with your real tests.
  def test_basic
    Pref.set(:use_ssl,true)
    assert Pref.server == '0000'
    Pref.update_attributes({:server=>'12345'})
    assert Pref.use_ssl
    assert Pref.server == '12345'
  end
end
