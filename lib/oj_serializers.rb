# frozen_string_literal: true

require 'oj_serializers/version'

begin
  require 'oj'
  require 'oj_serializers/setup'
rescue LoadError
  require 'json'
  require 'oj_serializers/json_writer'
end

require 'oj_serializers/serializer'
