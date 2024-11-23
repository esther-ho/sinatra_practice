class Vault
  # Add a vault associated with a user based on the given user id
  def self.add(user_id, vault_name)
    sql = "INSERT INTO vaults (user_id, name) VALUES ($1, $2)"
    DatabaseAccessor.query(sql, user_id, vault_name)
  end

  # Find a vault with the given vault name of a specific user
  def self.find_by_vault_name(user_id, vault_name)
    sql = "SELECT * FROM vaults WHERE user_id = $1 AND name ILIKE $2"
    result = DatabaseAccessor.query(sql, user_id, vault_name)
    result.first
  end
end
