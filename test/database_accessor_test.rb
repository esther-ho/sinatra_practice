ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/database_accessor"
require_relative "../lib/user"

class DatabaseAccessorTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
  end

  def test_delete_all_data
    User.add("admin", "123")

    user1 = User.find_by_username("admin")

    assert user1
    assert_equal 1, user1.id

    DatabaseAccessor.reset

    assert_nil User.find_by_username("admin")

    User.add("developer", "123")

    user2 = User.find_by_username("developer")

    assert user2
    assert_equal 1, user2.id
  end
end
