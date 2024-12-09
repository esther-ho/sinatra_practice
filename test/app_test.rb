ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    DatabaseAccessor.connect
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
  end

  def admin_session
    { "rack.session" => { user_id: 1, username: "admin" }}
  end

  def test_homepage
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Sign Up"
    assert_includes last_response.body, "Sign In"
  end

  def test_sign_up_form
    get "/users/signup"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(form action="/users" method="post")
    assert_includes last_response.body, %q(input id="username")
    assert_includes last_response.body, %q(input id="password")
    assert_includes last_response.body, %q(input id="password_confirmation")
    assert_includes last_response.body, %q(button type="submit")
  end

  def test_sign_up_username_taken
    User.add("admin", "secret")

    post "/users", { username: "admin", password: "123", password_confirmation: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username is already taken."
  end

  def test_sign_up_username_with_non_alphanumeric_characters
    post "/users", { username: "admin$1  ", password: "123", password_confirmation: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username must only contain alphanumeric characters."
  end

  def test_sign_up_passwords_not_matching
    post "/users", { username: "admin", password: "123", password_confirmation: "456" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords do not match."
  end

  def test_valid_sign_up
    post "/users", { username: "admin", password: "secret", password_confirmation: "secret" }

    assert_equal 302, last_response.status
    assert_match /\/admin$/, last_response["Location"]

    assert_equal 1, last_request.session[:user_id]
    assert_equal "admin", last_request.session[:username]

    user = User.find_by_username("admin")
    assert user
    assert user.authenticate("secret")
  end

  def test_create_vault_on_sign_up
    post "/users", { username: "admin", password: "secret", password_confirmation: "secret" }

    assert_equal 302, last_response.status
    assert_match /\/admin$/, last_response["Location"]

    user = User.find_by_username("admin")
    assert Vault.find_by_vault_name(user.id, "My Vault")
  end

  def test_sign_in_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(form action="/users/signin" method="post")
    assert_includes last_response.body, %q(input id="username")
    assert_includes last_response.body, %q(input id="password")
    assert_includes last_response.body, %q(button type="submit")
  end

  def test_sign_in_user_not_found
    post "/users/signin", { username: "developer", password: "123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid username and/or password."
  end

  def test_sign_in_invalid_password
    User.add("admin", "secret")

    post "/users/signin", { username: "admin", password: "sEcRET" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid username and/or password."
  end

  def test_valid_sign_in
    User.add("admin", "secret")

    post "/users/signin", { username: "admin", password: "secret" }

    assert_equal 302, last_response.status
    assert_match /\/admin$/, last_response["Location"]

    assert_equal 1, last_request.session[:user_id]
    assert_equal "admin", last_request.session[:username]
  end

  def test_redirect_user_if_signed_out
    get "/admin"

    assert_equal 302, last_response.status
    assert_match /\/users\/signin$/, last_response["Location"]
  end

  def test_display_user_dashboard_signed_in
    get "/admin", {}, admin_session

    assert_equal 200, last_response.status
  end
end
