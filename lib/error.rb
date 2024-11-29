class Error
  def initialize
    @errors = {}
  end

  # Assign the `error_type` as a key e.g. `:invalid_username`
  # Add messages related to an error into the array referenced by the key
  def add(error_type, message)
    errors[error_type] ||= []
    errors[error_type] << message
    self
  end

  # Return a hash where keys are the error type,
  # and values are the array of messages
  def details
    errors.clone.freeze
  end

  private

  attr_reader :errors
end
