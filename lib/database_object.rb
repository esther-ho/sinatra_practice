require 'time'

class DatabaseObject
  def initialize(record = {})
    assign_attributes(record) unless record.empty?
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
