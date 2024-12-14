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
end
