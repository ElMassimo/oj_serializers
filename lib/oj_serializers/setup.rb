# frozen_string_literal: true

require 'oj'

# NOTE: We automatically set the necessary configuration unless it had been
# explicitly set beforehand.
#
# `use_raw_json` must be enabled *before* `Oj.optimize_rails`. Rails 8.1
# memoizes an option-less encoder when the JSON encoder is assigned (which
# `Oj.optimize_rails` does), and `Oj::Rails::Encoder` captures `default_options`
# at construction. Enabling `use_raw_json` afterwards leaves that memoized
# encoder with `use_raw_json: false`, which double-encodes `JsonValue`.
unless Oj.default_options[:use_raw_json]
  require 'rails'
  Oj.default_options = { mode: :rails, use_raw_json: true }
  Oj.optimize_rails
end

# NOTE: Add an optimization to make it easier to work with a StringWriter
# transparently in different scenarios.
class Oj::StringWriter
  alias original_as_json as_json

  # Internal: ActiveSupport can pass an options argument to `as_json` when
  # serializing a Hash or Array.
  def as_json(_options = nil)
    original_as_json
  end

  # Internal: We can use `to_s` directly, this is not important but gives a
  # slight boost to a few use cases that use it for caching in Memcached.
  def to_json(_options = nil)
    to_s.delete_suffix("\n")
  end
end
