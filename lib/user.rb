require "bcrypt"

require_relative "database_object"

class User < DatabaseObject
  include BCrypt

  attr_reader :errors, :id, :username, :password

  # If the user has an invalid username and/or passwords,
  # return the `User` object with its updated `Error` instance.
  # Otherwise, add the user to the database and return the `User` instance
  def self.create(*options)
    user = new(*options)
    user.validate(:username, :password)
    return user if user.error?

    add(user.username, user.password)
    find_by_username(user.username)
  end

  # If the login credentials are invalid,
  # return a new `User` object with its updated `Error` instance.
  # Otherwise, return the `User` instance
  def self.login(username, password)
    valid_user = find_by_username(username)&.authenticate(password)

    unless valid_user
      user = new
      user.errors.add(:invalid_login_credentials,
                      "Invalid username and/or password.")
      return user
    end

    valid_user
  end

  # Add a new user to the `users` table
  def self.add(username, password)
    password_hash = Password.create(password)

    sql = "INSERT INTO users (username, password_hash) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, username, password_hash)
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

  private

  # Add error if username is not between 2 - 36 characters, or
  # has non-alphanumeric characters
  def username_validation
    return unless username_unique?

    username_errors = [
      { regexp: "^.{2,36}$",
        message: "Username should have between 2 and 36 characters." },
      { regexp: "^[a-zA-Z0-9]+$",
        message: "Username must only contain alphanumeric characters." }
    ]

    username_errors.each do |error|
      next if username =~ /#{error[:regexp]}/
      errors.add(:invalid_username, error[:message])
    end
  end

  # Return `true` if username is unique, and `false` otherwise
  # Add error if username is not unique
  def username_unique?
    return true unless self.class.find_by_username(username)
    errors.add(:invalid_username, "Username is already taken.")
    false
  end

  # Add error if passwords do not match
  def password_validation
    return if @password == @password_confirmation
    errors.add(:invalid_password, "Passwords do not match.")
  end
end
