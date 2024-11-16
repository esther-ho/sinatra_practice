require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "passwordmanager")
    @logger = logger
  end

  def disconnect
    @db.close
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
