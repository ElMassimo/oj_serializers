# frozen_string_literal: true

module OjSerializers
  def self.configuration
    @configuration ||= OjSerializers::Config.new
  end

  def self.configure
    yield(configuration)
  end
end

require 'oj'
require 'oj_serializers/config'
require 'oj_serializers/version'
require 'oj_serializers/setup'
require 'oj_serializers/serializer'
