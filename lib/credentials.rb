require "openssl"
require_relative "database_object"

class Credentials < DatabaseObject
  attr_reader :errors, :name

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

  # Add an error if the name is not between 1-64 characters
  def name_validation
    name_error = {
      regexp: "^.{1,64}$",
      message: "Name should have between 1 and 64 characters."
    }

    return if name =~ /#{name_error[:regexp]}/
    errors.add(:invalid_name, name_error[:message])
  end
end