require "minitest/autorun"

require_relative "../lib/error"

class ErrorTest < Minitest::Test
  def test_raises_error_initialize_with_argument
    assert_raises ArgumentError do
      Error.new('Test error.')
    end
  end
end
