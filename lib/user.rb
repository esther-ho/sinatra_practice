require "bcrypt"

class User
  include BCrypt

  # If a user is found, check that the passwords match
  def self.login(username, password)
    find_by_username(username)&.authenticate(password)
  end

  # Add a new user to the `users` table
  def self.add(username, password)
    sql = "INSERT INTO users (username, password_hash) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, username, password)
  end

  # Find a user from the `users` table based on the given username
  def self.find_by_username(username)
    sql = "SELECT * FROM users WHERE username = $1"
    result = DatabaseAccessor.query(sql, username)
    tuple = result.first

    create_user_from_tuple(tuple) if tuple
  end

  # Check if the given password matches the user's hashed password
  def authenticate(password)
    Password.new(@password_hash) == password ? self : false
  end

  class << self
    private

    # Instantiate a new `User` object
    # Set its instance variables based on attributes and values from the tuple
    def create_user_from_tuple(tuple)
      user = new
      tuple.each { |k, v| user.instance_variable_set("@#{k}", v) }
      user
    end
  end
end
