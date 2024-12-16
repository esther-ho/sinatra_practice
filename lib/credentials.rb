require "openssl"
require_relative "database_object"

class Credentials < DatabaseObject
  attr_reader :errors, :name, :username

  @@cipher = OpenSSL::Cipher.new('AES-256-CBC')

  def initialize(*options)
    super(*options)
    generate_key
  end

  def add
    keys = ["user_id", "name", "username", "encrypted_password", "iv", "notes"]
    values = [@user_id, name, username, @encrypted_password, @iv, @notes]

    sql = <<~SQL
      INSERT INTO credentials (#{keys.join(', ')})
      VALUES ($1, $2, $3, $4, $5, $6)
      SQL

    DatabaseAccessor.query(sql, *values)
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

  # Add an error if the username is not between 2-256 characters
  def username_validation
    username_error = {
      regexp: "^.{2,256}$",
      message: "Username should have between 2 and 256 characters."
    }

    return if username =~ /#{username_error[:regexp]}/
    errors.add(:invalid_username, username_error[:message])
  end
end
