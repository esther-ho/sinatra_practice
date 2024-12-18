ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/database_accessor"
require_relative "../lib/user"
require_relative "../lib/credentials"

class DatabaseAccessorTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
  end

  def test_delete_all_data
    User.create(username: "admin", password: "test123", password_confirmation: "test123")
    Credentials.new(user_id: 1, name: "Example.com", username: "johndoe").add

    user1 = User.find_by_username("admin")
    credentials1 = Credentials.find_by_name_and_username("Example.com", "johndoe")

    assert user1
    assert_equal 1, user1.id

    assert credentials1
    assert_equal 1, credentials1.id

    DatabaseAccessor.reset

    assert_nil User.find_by_username("admin")
    assert_nil Credentials.find_by_name_and_username("Example.com", "johndoe")

    User.create(username: "developer", password: "test123", password_confirmation: "test123")
    Credentials.new(user_id: 1, name: "Example.org", username: "johndoe").add

    user2 = User.find_by_username("developer")
    credentials2 = Credentials.find_by_name_and_username("Example.org", "johndoe")

    assert user2
    assert_equal 1, user2.id

    assert credentials2
    assert_equal 1, credentials2.id
  end
end
