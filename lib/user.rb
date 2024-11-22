require "bcrypt"

class LoginError < StandardError; end

class User
  include BCrypt

  def initialize(*options)
    set_attributes(*options) unless options.empty?
  end

  # If the user is not found and/or passwords don't match, raise LoginError
  # Otherwise, return the `User` instance
  def self.login(username, password)
    valid_user = find_by_username(username)&.authenticate(password)
    raise LoginError, "Invalid username and/or password." unless valid_user
    valid_user
  end

  # Add a new user to the `users` table
  def self.add(username, password)
    sql = "INSERT INTO users (username, password_hash) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, username, password)
  end

  # Find a user from the `users` table based on the given username
  # Instantiate a new `User` object if a valid user is found
  # Set its instance variables based on attributes and values from the tuple
  def self.find_by_username(username)
    sql = "SELECT * FROM users WHERE username = $1"
    result = DatabaseAccessor.query(sql, username)
    tuple = result.first

    new(tuple) if tuple
  end

  # Check if the given password matches the user's hashed password
  def authenticate(password)
    Password.new(@password_hash) == password ? self : false
  end

  # Store only the `id` and `username` of a user in a session
  def session_hash
    { id: @id, username: @username }
  end

  private

  def set_attributes(options)
    options.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
  end
end
