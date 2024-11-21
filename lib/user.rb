class User
  # Add a new user to the `users` table
  def add_user(username, password)
    sql = "INSERT INTO users (username, password_hash) VALUES ($1, $2)"
    query(sql, username, password)
  end

  # Find a user from the `users` table based on the given username
  def find_user(username)
    sql = "SELECT * FROM users WHERE username = $1"
    result = query(sql, username)
    result.first
  end
end
