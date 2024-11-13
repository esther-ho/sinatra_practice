ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../lib/password_manager"

class PasswordManagerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_homepage
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Sign Up"
    assert_includes last_response.body, "Sign In"
  end
end
