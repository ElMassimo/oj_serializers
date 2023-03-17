# frozen_string_literal: true

ENV["BENCHMARK"] = "true"

require 'spec_helper'
require 'benchmark/ips'
require 'benchmark/memory'
require 'benchmark'
require 'memory_profiler'

require 'rails'
require 'active_support/json'
require 'oj_serializers/compat'
require 'support/models/album'
require 'support/serializers/active_model_serializer'
require 'support/serializers/album_serializer'
require 'support/serializers/blueprints'
require 'support/serializers/legacy_serializers'
require 'support/serializers/option_serializer'
