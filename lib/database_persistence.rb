require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "passwordmanager")
    @logger = logger
  end

  def disconnect
    @db.close
  end
end
