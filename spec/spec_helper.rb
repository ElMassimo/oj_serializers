# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'

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

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
