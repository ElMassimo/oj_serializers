# frozen_string_literal: true

require 'json'

# Public: A pure-Ruby replacement for Oj::StringWriter that builds JSON via
# string concatenation. Implements the same API used by the generated
# `write_to_json` code so the serializer can work without the oj gem.
class OjSerializers::JsonWriter
  def initialize(**)
    @io = +""
    @stack = [] # tracks [:object/:array, needs_comma]
    @after_key = false
  end

  # Write the opening `{` of a JSON object.
  def push_object
    write_comma_if_needed
    @after_key = false
    @io << "{"
    @stack.push([:object, false])
  end

  # Write the opening `[` of a JSON array.
  def push_array
    write_comma_if_needed
    @after_key = false
    @io << "["
    @stack.push([:array, false])
  end

  # Write the closing `}` or `]` for the current nesting level.
  def pop
    type, = @stack.pop
    @io << (type == :object ? "}" : "]")
    @stack.last[1] = true if @stack.any?
    @after_key = false
  end

  # Write a value, optionally with a key (for object members).
  #
  # writer.push_value("hello", "name")  =>  "name":"hello"
  # writer.push_value(42)               =>  42
  def push_value(value, key = nil)
    write_comma_if_needed
    @after_key = false
    if key
      @io << "#{JSON.generate(key)}:"
    end
    @io << json_encode(value)
    @stack.last[1] = true if @stack.any?
  end

  # Write a key for the next value. Used for associations where the serializer
  # will call push_object or push_array next.
  #
  # writer.push_key("songs")  =>  "songs":
  def push_key(key)
    write_comma_if_needed
    @io << "#{JSON.generate(key)}:"
    @after_key = true
  end

  # Embed a raw JSON string directly. Used for cached serialized items.
  def push_json(json)
    write_comma_if_needed
    @after_key = false
    @io << json.chomp("\n")
    @stack.last[1] = true if @stack.any?
  end

  # Return the built JSON string.
  def to_s
    @io
  end

  # Compatibility: return the JSON string without a trailing newline.
  def to_json(_options = nil)
    @io
  end

  # Compatibility: return self so it can be used transparently.
  def as_json(_options = nil)
    self
  end

private

  def write_comma_if_needed
    return if @after_key

    if @stack.any? && @stack.last[1]
      @io << ","
    end
    @after_key = false
  end

  def json_encode(value)
    case value
    when String then JSON.generate(value)
    when Integer, Float then value.to_s
    when true then "true"
    when false then "false"
    when nil then "null"
    when OjSerializers::JsonValue then value.to_s
    else JSON.generate(value)
    end
  end
end
