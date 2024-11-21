class User
  # Add a new user to the `users` table
  def self.add_user(username, password)
    sql = "INSERT INTO users (username, password_hash) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, username, password)
  end

  # Find a user from the `users` table based on the given username
  def self.find_user(username)
    sql = "SELECT * FROM users WHERE username = $1"
    result = DatabaseAccessor.query(sql, username)
    result.first
  end
end
