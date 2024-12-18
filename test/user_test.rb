ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/user"
require_relative "../lib/database_accessor"

class UserTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
  end

  def test_add_user
    assert_nil User.find_by_username("admin")

    user = User.create(
      username: "admin",
      password: "test123",
      password_confirmation: "test123"
      )

    assert user
    assert user.authenticate("test123")
  end

  def test_add_duplicate_user
    User.create(
      username: "admin",
      password: "test123",
      password_confirmation: "test123"
      )

    assert_raises PG::UniqueViolation do
      User.new(
        username: "admin",
        password: "test456",
        password_confirmation: "test456"
        ).add
    end
  end

  def test_find_user
    User.create(
      username: "admin",
      password: "test123",
      password_confirmation: "test123"
      )

    user = User.find_by_username("admin")

    assert user
    assert_equal "admin", user.username
    assert user.authenticate("test123")
  end

  def test_find_nonexistent_user
    assert_nil User.find_by_username("developer")
  end
end
