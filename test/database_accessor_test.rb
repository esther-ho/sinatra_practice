ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/database_accessor"
require_relative "../lib/user"
require_relative "../lib/vault"

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
    Vault.add("1", "My Vault")

    user1 = User.find_by_username("admin")
    vault1 = Vault.find_by_vault_name("1", "My vault")

    assert user1
    assert_equal "1", user1.id

    assert vault1
    assert_equal "1", vault1.id

    DatabaseAccessor.reset

    assert_nil User.find_by_username("admin")
    assert_nil Vault.find_by_vault_name("1", "My Vault")

    User.add("developer", "123")
    Vault.add("1", "My Vault")

    user2 = User.find_by_username("developer")
    vault2 = Vault.find_by_vault_name(1, "My Vault")

    assert user2
    assert_equal "1", user2.id

    assert vault2
    assert_equal "1", vault2.id
  end
end
