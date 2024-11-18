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

  # Delete all tables
  def delete_all_data
    sql = <<~SQL
    DELETE FROM users;
    ALTER SEQUENCE users_id_seq RESTART;
    DELETE FROM vaults;
    ALTER SEQUENCE vaults_id_seq RESTART;
    SQL

    @db.exec(sql)
  end

  # Add a vault associated with a user based on the given username
  def add_vault(username, vault_name)
    user = find_user(username)
    user_id = user["id"]

    sql = "INSERT INTO vaults (user_id, name) VALUES ($1, $2)"
    query(sql, user_id, vault_name)
  end

  # Find a vault with the given vault name of a specific user
  def find_vault(username, vault_name)
    user = find_user(username)
    return unless user
    user_id = user["id"]

    sql = <<~SQL
    SELECT * FROM vaults
    WHERE user_id = $1
    AND name ILIKE $2
    SQL

    result = query(sql, user_id, vault_name)
    result.first
  end

  private

  def query(statement, *params)
    @logger&.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
