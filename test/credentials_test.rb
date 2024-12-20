ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/credentials"
require_relative "../lib/database_accessor"
require_relative "../lib/user"

class CredentialsTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
    User.create(
      username: "johndoe",
      password: "test123",
      password_confirmation: "test123")
  end

  def encryption_file_path
    File.expand_path("encryption_key.yml", __dir__)
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
    FileUtils.rm_f(encryption_file_path)
  end

  def test_generate_key_on_instantiation
    Credentials.new
    assert File.file?(encryption_file_path)
  end

  def test_wrong_name_length
    credentials = Credentials.new(name: "")
    credentials.validate(:name)
    assert credentials.error?
    assert_equal "Name should have between 1 and 64 characters.", credentials.error_messages

    credentials = Credentials.new(name: "a" * 65)
    credentials.validate(:name)
    assert credentials.error?
    assert_equal "Name should have between 1 and 64 characters.", credentials.error_messages
  end

  def test_wrong_username_length
    credentials = Credentials.new(username: "a")
    credentials.validate(:username)
    assert credentials.error?
    assert_equal "Username should have between 2 and 256 characters.", credentials.error_messages

    credentials = Credentials.new(username: "a" * 257)
    credentials.validate(:username)
    assert credentials.error?
    assert_equal "Username should have between 2 and 256 characters.", credentials.error_messages
  end

  def test_add_wrong_name_length
    credentials = Credentials.new(name: "", user_id: 1, username: "johndoe")
    assert_raises PG::CheckViolation do
      credentials.add
    end

    credentials = Credentials.new(name: "a" * 65, user_id: 1, username: "johndoe")
    assert_raises PG::CheckViolation do
      credentials.add
    end
  end

  def test_add_wrong_username_length
    credentials = Credentials.new(username: "a", user_id: 1, name: "Example.com")
    assert_raises PG::CheckViolation do
      credentials.add
    end

    credentials = Credentials.new(username: "a" * 257, user_id: 1, name: "Example.com")
    assert_raises PG::CheckViolation do
      credentials.add
    end
  end

  def test_find_existing_credentials_by_name_and_username
    credentials = Credentials.new(user_id: 1, name: "Example.com", username: "johndoe")
    credentials.add
    found = Credentials.find_by_name_and_username("Example.com", "johndoe")

    assert_equal "Example.com", found.name
    assert_equal "johndoe", found.username
  end

  def test_find_nonexistent_credentials
    not_found = Credentials.find_by_name_and_username("Example.org", "johndoe")
    assert_nil not_found
  end

  def test_unique_credentials
    credentials1 = Credentials.new(user_id: 1, name: "Example.com", username: "johndoe")
    assert credentials1.unique?
    refute credentials1.error?

    credentials1.add
    assert credentials1.unique?

    credentials2 = Credentials.new(user_id: 1, name: "Example.com", username: "johndoe")
    refute credentials2.unique?
    assert credentials2.error?
    assert_equal "An entry with this name and username already exists.", credentials2.error_messages
  end

  def test_encrypt_password
    credentials = Credentials.new(password: "test123")
    assert_equal "test123", credentials.instance_variable_get(:@password)

    credentials.encrypt_password
    assert_nil credentials.instance_variable_get(:@password)
    refute_equal "test123", credentials.instance_variable_get(:@encrypted_password)
  end

  def test_create_valid_credentials_with_password
    Credentials.create(user_id: 1, name: "Example.com", username: "johndoe", password: "test123")
    found = Credentials.find_by_name_and_username("Example.com", "johndoe")

    assert found
    assert_equal "Example.com", found.name
    assert_equal "johndoe", found.username
    assert found.instance_variable_get(:@encrypted_password)
    assert found.instance_variable_get(:@iv)
    refute_equal "test123", found.instance_variable_get(:@encrypted_password)
  end

  def test_create_valid_credentials_without_password
    Credentials.create(user_id: 1, name: "Example.com", username: "johndoe", password: "")
    found = Credentials.find_by_name_and_username("Example.com", "johndoe")

    assert found
    assert_equal "Example.com", found.name
    assert_equal "johndoe", found.username
    assert_nil found.instance_variable_get(:@encrypted_password)
    assert_nil found.instance_variable_get(:@iv)
  end

  def test_create_credentials_with_nonunique_entry
    Credentials.create(user_id: 1, name: "A.com", username: "test")
    credentials = Credentials.create(user_id: 1, name: "A.com", username: "test")

    assert credentials.error?
    assert_equal "An entry with this name and username already exists.", credentials.error_messages
  end

  def test_create_credentials_with_invalid_name
    credentials = Credentials.create(name: "", user_id: 1, username: "test")

    assert credentials.error?
    assert_equal "Name should have between 1 and 64 characters.", credentials.error_messages
    assert_nil Credentials.find_by_name_and_username("", "test")
  end

  def test_create_credentials_with_invalid_username
    credentials = Credentials.create(username: "a", user_id: 1, name: "A.com")

    assert credentials.error?
    assert_equal "Username should have between 2 and 256 characters.", credentials.error_messages
    assert_nil Credentials.find_by_name_and_username("A.com", "a")
  end

  def test_find_all_entries_by_user_id
    Credentials.create(user_id: 1, name: "Google", username: "johndoe")
    Credentials.create(user_id: 1, name: "Mozilla", username: "johndoe" )

    credentials_arr = Credentials.find_all_by_user_id(1)
    assert_equal 2, credentials_arr.size

    assert_equal "Google", credentials_arr.first.name
    assert_equal "johndoe", credentials_arr.first.username

    assert_equal "Mozilla", credentials_arr.last.name
    assert_equal "johndoe", credentials_arr.last.username
  end

  def test_find_entries_for_nonexistent_user_id
    assert_equal 0, Credentials.find_all_by_user_id(2).size
  end

  def test_decrypt_encrypted_password
    credentials = Credentials.create(
      user_id: 1,
      name: "Test",
      username: "johndoe",
      password: "test123"
      )

    assert_equal "test123", credentials.decrypt_password
  end

  def test_decrypt_nonexisting_password
    credentials = Credentials.create(
      user_id: 1,
      name: "Test",
      username: "johndoe"
    )

    assert_nil credentials.decrypt_password
  end
end
