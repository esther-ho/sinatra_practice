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

    User.add("admin", "123")
    user = User.find_by_username("admin")

    assert user
    assert user.authenticate("123")
  end

  def test_find_user
    User.add("admin", "123")

    user = User.find_by_username("admin")

    assert user
    assert_equal "admin", user.username
    assert user.authenticate("123")
  end

  def test_find_nonexistent_user
    assert_nil User.find_by_username("developer")
  end
end
