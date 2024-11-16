require "pg"

class DatabasePersistence
  def initialize(logger = nil)
    if ENV["RACK_ENV"] == "test"
      @db = PG.connect(dbname: "passwordmanagertest")
    else
      @db = PG.connect(dbname: "passwordmanager")
    end

    @logger = logger
  end

  def disconnect
    @db.close
  end

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

  private

  def query(statement, *params)
    @logger&.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
