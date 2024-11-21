require "pg"

class DatabasePersistence
  @@db = nil
  @@logger = nil

  def self.connect(logger = nil)
    @@db = PG.connect(dbname: load_database)
    @@logger = logger
  end

  def self.disconnect
    @@db.close
  end

  # Delete all tables
  def self.delete_all_data
    sql = <<~SQL
    DELETE FROM users;
    ALTER SEQUENCE users_id_seq RESTART;
    DELETE FROM vaults;
    ALTER SEQUENCE vaults_id_seq RESTART;
    SQL

    @@db.exec(sql)
  end

  def self.query(statement, *params)
    @@logger&.info "#{statement}: #{params}"
    @@db.exec_params(statement, params)
  end

  class << self
    private

    def load_database
      ENV["RACK_ENV"] == "test" ? "passwordmanagertest" : "passwordmanager"
    end
  end
end
