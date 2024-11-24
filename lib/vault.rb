class Vault
  def initialize(*options)
    set_attributes(*options) unless options.empty?
  end

  # Add a vault associated with a user based on the given user id
  def self.add(user_id, vault_name)
    sql = "INSERT INTO vaults (user_id, name) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, user_id, vault_name)
  end

  # Find a vault with the given vault name of a specific user
  # Instantiate a new `Vault` object if a valid vault is found
  def self.find_by_vault_name(user_id, vault_name)
    sql = "SELECT * FROM vaults WHERE user_id = $1 AND name ILIKE $2"
    result = DatabaseAccessor.query(sql, user_id, vault_name)
    tuple = result.first

    new(tuple) if tuple
  end

  private

  def set_attributes(options)
    options.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
  end
end
