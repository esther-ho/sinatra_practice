require "openssl"
require_relative "database_object"

class Credentials < DatabaseObject
  @@cipher = OpenSSL::Cipher.new('AES-256-CBC')

  def initialize(*options)
    super(*options)
    generate_key
  end

  private

  def file_path
    if ENV["RACK_ENV"] == "test"
      File.expand_path("../test/encryption_key.yml", __dir__)
    else
      File.expand_path("encryption_key.yml", __dir__)
    end
  end

  def generate_key
    if File.file?(file_path)
      @@key = File.read(file_path)
    else
      @@key = @@cipher.random_key
      File.write(file_path, @@key)
    end
  end
end
