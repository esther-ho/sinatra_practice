require "minitest/autorun"

require_relative "../lib/errors"

class ErrorsTest < Minitest::Test
  def setup
    @errors = Errors.new
    @errors.add(:invalid_username, "Username is already taken.")
    @errors.add(:invalid_username,
                "Username must only contain alphanumeric characters.")
  end

  def test_raises_error_initialize_with_argument
    assert_raises ArgumentError do
      Errors.new('Test error.')
    end
  end

  def test_add_error
    messages = ["Username is already taken.",
                "Username must only contain alphanumeric characters."]
    assert_equal ({ invalid_username: messages }), @errors.details
  end

  def test_empty
    assert Errors.new.empty?
  end

  def test_messages
    @errors.add(:invalid_password, "Passwords do not match.")
    messages = ["Username is already taken.",
                "Username must only contain alphanumeric characters.",
                "Passwords do not match."]
    assert_equal messages, @errors.messages
  end
end
