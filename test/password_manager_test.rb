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

  # Test routes

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

    assert_nil Validatable.error_for_missing_user("admin", @storage)
    assert_nil Validatable.error_for_invalid_password("admin", "secret", @storage)
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

  # Test database functionality

  def test_add_user
    assert_nil @storage.find_user("admin")

    @storage.add_user("admin", "123")
    user = @storage.find_user("admin")

    assert user
    assert_equal "123", user["password_hash"]
  end

  def test_find_user
    @storage.add_user("admin", "123")

    user = @storage.find_user("admin")

    assert user
    assert_equal "admin", user["username"]
    assert_equal "123", user["password_hash"]

    assert_nil @storage.find_user("developer")
  end

  def test_delete_all_data
    @storage.add_user("admin", "123")
    @storage.add_vault(1, "My Vault")

    user1 = @storage.find_user("admin")
    vault1 = @storage.find_vault(1, "My vault")

    assert user1
    assert_equal "1", user1["id"]

    assert vault1
    assert_equal "1", vault1["id"]

    @storage.delete_all_data

    assert_nil @storage.find_user("admin")
    assert_nil @storage.find_vault(1, "My Vault")

    @storage.add_user("developer", "123")
    @storage.add_vault(1, "My Vault")

    user2 = @storage.find_user("developer")
    vault2 = @storage.find_vault(1, "My Vault")

    assert user2
    assert_equal "1", user2["id"]

    assert vault2
    assert_equal "1", vault2["id"]
  end

  def test_add_vault_with_valid_user_id
    @storage.add_user("admin", "123")
    @storage.add_vault(1, "My Vault")

    vault = @storage.find_vault(1, "My Vault")
    assert vault
    assert_equal "1", vault["user_id"]
    assert_equal "My Vault", vault["name"]
  end

  def test_add_vault_without_valid_user_id
    assert_raises PG::ForeignKeyViolation do
      @storage.add_vault(1, "My Vault")
    end

    assert_nil @storage.find_vault(1, "My Vault")
  end
end
