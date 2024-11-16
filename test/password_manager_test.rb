ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../lib/password_manager"

class PasswordManagerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @storage = DatabasePersistence.new
  end

  def teardown
    @storage.delete_all_data
    @storage.disconnect
  end

  def test_homepage
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Sign Up"
    assert_includes last_response.body, "Sign In"
  end

  def test_sign_up_form
    get "/users/sign-up"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(form action="/users" method="post")
    assert_includes last_response.body, %q(input id="username")
    assert_includes last_response.body, %q(input id="password")
    assert_includes last_response.body, %q(input id="repeat_password")
    assert_includes last_response.body, %q(button type="submit")
  end

  def test_sign_up_username_taken
    @storage.add_user("admin", BCrypt::Password.create("secret"))

    post "/users", { username: "admin", password: "123", repeat_password: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username is already taken."
  end

  def test_sign_up_username_with_non_alphanumeric_characters
    post "/users", { username: "admin$1  ", password: "123", repeat_password: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username must only contain alphanumeric characters."
  end

  def test_sign_up_passwords_not_matching
    post "/users", { username: "admin", password: "123", repeat_password: "456" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords do not match."
  end

  def test_valid_sign_up
    post "/users", { username: "admin", password: "secret", repeat_password: "secret" }

    assert_equal 200, last_response.status
    assert_equal "admin", last_request.session[:user]
  end

  def test_sign_in_form
    get "/users/sign-in"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(form action="/users/sign-in" method="post")
    assert_includes last_response.body, %q(input id="username")
    assert_includes last_response.body, %q(input id="password")
    assert_includes last_response.body, %q(button type="submit")
  end

  def test_sign_in_user_not_found
    post "/users/sign-in", { username: "developer", password: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "User not found."
  end

  def test_sign_in_invalid_password
    @storage.add_user("admin", BCrypt::Password.create("secret"))

    post "/users/sign-in", { username: "admin", password: "sEcRET" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid password."
  end

  def test_valid_sign_in
    @storage.add_user("admin", BCrypt::Password.create("secret"))

    post "/users/sign-in", { username: "admin", password: "secret" }

    assert_equal 200, last_response.status
    assert_equal "admin", last_request.session[:user]
  end
end
