require "pg"

class DatabasePersistence
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
    sql = <<~SQL
    DELETE FROM users;
    ALTER SEQUENCE users_id_seq RESTART;
    DELETE FROM vaults;
    ALTER SEQUENCE vaults_id_seq RESTART;
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
