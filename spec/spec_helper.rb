# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

require 'bundler/setup'
require 'oj_serializers'
require 'pry-byebug'
require 'bson'

class BSON::ObjectId
  # Override: We want the internal value of the id when serializing with
  # ActiveModelSerializers instead of a { oid: value } hash.
  def as_json(_options = nil)
    to_s
  end
end

module JsonHelpers
  def parse_json(json = response.body)
    item = JSON.parse(json)
    item.is_a?(Array) ? item.map(&:deep_symbolize_keys) : item.deep_symbolize_keys!
  end

  def expect_parsed_json(json = response.body)
    expect(parse_json(json))
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include JsonHelpers
end
