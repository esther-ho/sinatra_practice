require "pg"

class DatabaseAccessor
  @@db = nil
  @@logger = nil

  def self.connect(logger = nil)
    @@db = PG.connect(dbname: load_database)
    @@logger ||= logger
  end

  def self.disconnect
    @@db.close
  end

  # Delete all data in tables and reset id sequences to 1
  def self.reset
    ensure_connection

    sql = <<~SQL
    DELETE FROM users;
    DELETE FROM credentials;
    ALTER SEQUENCE users_id_seq RESTART;
    ALTER SEQUENCE credentials_id_seq RESTART;
    SQL

    @@db.exec(sql)
  end

  def self.query(statement, *params)
    ensure_connection

    @@logger&.info "#{statement}: #{params}"
    @@db.exec_params(statement, params)
  end

  class << self
    private

    def load_database
      ENV["RACK_ENV"] == "test" ? "passwordmanagertest" : "passwordmanager"
    end

    def ensure_connection
      connect if @@db.nil? || @@db.finished?
    end
  end
end
