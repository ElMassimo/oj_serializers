# frozen_string_literal: true

# Public: Allows to prevent double encoding an existing JSON string.
#
# NOTE: Oj's raw_json option means there's no performance overhead, as it would
# occur with the previous alternative of parsing the JSON string.
class OjSerializers::JsonValue
  # Helper: Expects an Array of JSON-encoded strings and wraps them in a JSON array.
  def self.array(json_rows)
    new("[#{json_rows.join(',')}]")
  end

  def initialize(json)
    @json = json
  end

  # Public: Return the internal json when using string interpolation.
  def to_s
    @json
  end

  # Internal: Used by Oj::Rails::Encoder because we use the `raw_json` option.
  def raw_json(*)
    @json
  end

  # Internal: Used by Oj::Rails::Encoder when found inside a Hash or Array.
  def as_json(_options = nil)
    self
  end
end
