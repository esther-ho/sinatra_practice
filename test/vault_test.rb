ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/vault"
require_relative "../lib/user"
require_relative "../lib/database_accessor"

class VaultTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
  end

  def test_add_vault_with_valid_user_id
    User.add("admin", "123")
    Vault.add(1, "My Vault")

    vault = Vault.find_by_vault_name(1, "My Vault")
    assert vault
    assert_equal 1, vault.user_id
    assert_equal "My Vault", vault.name
  end

  def test_add_vault_without_valid_user_id
    assert_raises PG::ForeignKeyViolation do
      Vault.add(1, "My Vault")
    end

    assert_nil Vault.find_by_vault_name(1, "My Vault")
  end

  def test_find_vault_with_valid_user_id
    User.add("admin", "123")
    Vault.add(1, "My Vault")

    assert Vault.find_by_vault_name(1, "My Vault")
    assert Vault.find_by_vault_name(1, "my vault")
    assert_nil Vault.find_by_vault_name(1, "test vault")
  end

  def test_find_vault_without_valid_user_id
    assert_nil Vault.find_by_vault_name(1, "my vault")
  end
end
