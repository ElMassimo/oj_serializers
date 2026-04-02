# frozen_string_literal: true

# Public: Allows to prevent double encoding an existing JSON string.
#
# NOTE: Uses JSON::Fragment when available to avoid re-parsing overhead.
class JsonSerializers::JsonValue
  # Public: Expects json to be a JSON-encoded string.
  def initialize(json)
    @json = json
  end

  # Public: Expects an Array of JSON-encoded strings and wraps them in a JSON array.
  #
  # Returns a JsonValue representing a JSON-encoded array.
  def self.array(json_rows)
    new("[#{json_rows.join(',')}]")
  end

  # Public: Return the internal json when using string interpolation.
  def to_s
    @json
  end

  # Internal: Returns the raw JSON string for libraries that support raw_json.
  def raw_json(*)
    @json
  end

  # Internal: Return the raw JSON string for JSON.generate compatibility.
  def to_json(_options = nil)
    @json
  end

  # Internal: Returns a JSON::Fragment so JSON.generate embeds the
  # pre-encoded string directly without re-parsing.
  def as_json(_options = nil)
    defined?(JSON::Fragment) ? JSON::Fragment.new(@json) : self
  end
end
