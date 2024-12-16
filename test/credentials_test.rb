ENV["RACK_ENV"] = "test"

require "minitest/autorun"

require_relative "../lib/credentials"
require_relative "../lib/database_accessor"

class CredentialsTest < Minitest::Test
  def setup
    DatabaseAccessor.connect
  end

  def encryption_file_path
    File.expand_path("encryption_key.yml", __dir__)
  end

  def teardown
    DatabaseAccessor.reset
    DatabaseAccessor.disconnect
    FileUtils.rm(encryption_file_path)
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
end
