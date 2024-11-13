ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../lib/password_manager"

class PasswordManagerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root_page
    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Hello world"
  end
end
