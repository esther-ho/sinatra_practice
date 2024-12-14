require 'time'

require_relative "errors"

class DatabaseObject
  def initialize(record = {})
    assign_attributes(record) unless record.empty?
    @errors = Errors.new
  end

  # Return `true` if there are errors, and `false` otherwise
  def error?
    !errors.empty?
  end

  # Return all error messages as a string
  def error_messages
    errors.messages.join(' ')
  end

  def validate(*attributes)
    attributes.each { |attribute| send("#{attribute}_validation") }
  end

  private

  def assign_attributes(record)
    record.each do |key, value|
      value = case key
              when /id$/ then value.to_i
              when /at$/ then Time.parse(value)
              else            value
              end

      instance_variable_set("@#{key}", value)
    end
  end
end
