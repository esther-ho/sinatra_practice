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

    post "/users", { username: "admin", password: "test123", password_confirmation: "test123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username is already taken."
  end

  def test_sign_up_username_with_non_alphanumeric_characters
    post "/users", { username: "admin$1  ", password: "test123", password_confirmation: "test123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username must only contain alphanumeric characters."
  end

  def test_sign_up_username_wrong_length
    post "/users", { username: "a", password: "test123", password_confirmation: "test123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username should have between 2 and 36 characters."

    post "/users", { username: "aaaaaaaabbbbbbbbcccccccdddddddeeeeeee",
                     password: "test123", password_confirmation: "test123"}

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username should have between 2 and 36 characters."
  end

  def test_sign_up_passwords_not_matching
    post "/users", { username: "admin", password: "test123", password_confirmation: "test456" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords do not match."
  end

  def test_sign_up_passwords_wrong_length
    post "/users", { username: "admin", password: "t123", password_confirmation: "t123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords should have between 6 and 125 characters."

    post "/users", { username: "admin", password: ("test" + "1" * 125),
                     password_confirmation: ("test" + "1" * 125)}

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords should have between 6 and 125 characters."
  end

  def test_sign_up_passwords_no_letters_or_numbers
    post "/users", { username: "admin", password: "tester", password_confirmation: "tester" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords should have at least one letter and one number."

    post "/users", { username: "admin", password: "123456", password_confirmation: "123456" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Passwords should have at least one letter and one number."
  end

  def test_valid_sign_up
    post "/users", { username: "admin", password: "secret123", password_confirmation: "secret123" }

    assert_equal 302, last_response.status
    assert_match /\/admin$/, last_response["Location"]

    assert_equal 1, last_request.session[:user_id]
    assert_equal "admin", last_request.session[:username]

    user = User.find_by_username("admin")
    assert user
    assert user.authenticate("secret123")
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
    post "/users/signin", { username: "developer", password: "test123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid username and/or password."
  end

  def test_sign_in_invalid_password
    User.add("admin", "secret123")

    post "/users/signin", { username: "admin", password: "sEcRET123" }

    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid username and/or password."
  end

  def test_valid_sign_in
    User.add("admin", "secret123")

    post "/users/signin", { username: "admin", password: "secret123" }

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

  def test_add_new_credentials_form
    get "/admin/passwords/add", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(form action="/admin/passwords" method="post")
    assert_includes last_response.body, %q(input id="entry_name")
    assert_includes last_response.body, %q(input id="entry_username")
    assert_includes last_response.body, %q(input id="entry_password")
    assert_includes last_response.body, %q(textarea id="entry_notes")
    assert_includes last_response.body, %q(input type="submit")
  end
end
