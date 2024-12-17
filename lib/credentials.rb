require "openssl"
require "base64"
require_relative "database_object"

class Credentials < DatabaseObject
  attr_reader :errors, :id, :name, :username

  @@cipher = OpenSSL::Cipher.new('AES-256-CBC')

  def initialize(*options)
    super(*options)
    generate_key
  end

  # If the credentials set is not unique or has an invalid name/username,
  # return the `Credentials` object with the updated `Errors` instance
  # Otherwise, add the credentials to the database and return the instance
  def self.create(*options)
    credentials = new(*options)
    return credentials unless credentials.unique?
    credentials.validate(:name, :username)
    return credentials if credentials.error?

    credentials.add
    credentials
  end

  # Find a record with a matching name and username
  # If a record is found, return a `Credential` instance with the relevant data
  # If not, return `nil`
  def self.find_by_name_and_username(name, username)
    sql = "SELECT * FROM credentials WHERE name = $1 AND username = $2"
    result = DatabaseAccessor.query(sql, name, username)
    tuple = result.first

    new(tuple) if tuple
  end

  # Encrypt the password if it exists
  # Add a new credentials set to the `credentials` table
  # Return the `id` of the inserted record and assign it to `@id`
  def add
    encrypt_password if @password

    keys = ["user_id", "name", "username", "encrypted_password", "iv", "notes"]
    values = [@user_id, name, username, @encrypted_password, @iv, @notes]

    sql = <<~SQL
    INSERT INTO credentials (#{keys.join(', ')})
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING id
    SQL

    result = DatabaseAccessor.query(sql, *values)
    @id = result.first["id"].to_i
  end

  # Generate an iv, and use the cipher key and iv to encrypt the password
  # Remove `@password` and store the encrypted password in `@encrypted_password`
  # Encode the iv and password so they can be inserted into `credentials`
  def encrypt_password
    cipher = @@cipher
    cipher.encrypt
    cipher.key = @@key
    @iv = cipher.random_iv

    password = remove_instance_variable(:@password)
    @encrypted_password = cipher.update(password) + cipher.final
    encode_iv_and_password
  end

  # Return `false` and update `@errors` if a record with the same name and
  # username but with a different id is found. Return `true` otherwise.
  def unique?
    other = self.class.find_by_name_and_username(name, username)
    return true unless other && other.id != id

    message = "An entry with this name and username already exists."
    errors.add(:invalid_credentials, message)
    false
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

  # Encode the encrypted password and iv in Base64 from the original ASCII-8BIT
  def encode_iv_and_password
    @iv = Base64.encode64(@iv)
    @encrypted_password = Base64.encode64(@encrypted_password)
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
