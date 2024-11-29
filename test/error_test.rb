require "minitest/autorun"

require_relative "../lib/error"

class ErrorTest < Minitest::Test
  def setup
    @errors = Error.new
    @errors.add(:invalid_username, "Username is already taken.")
    @errors.add(:invalid_username,
                "Username must only contain alphanumeric characters.")
  end

  def test_raises_error_initialize_with_argument
    assert_raises ArgumentError do
      Error.new('Test error.')
    end
  end

  def test_add_error
    messages = ["Username is already taken.",
                "Username must only contain alphanumeric characters."]
    assert_equal ({ invalid_username: messages }), @errors.details
  end

  def test_empty
    assert Error.new.empty?
  end
end
