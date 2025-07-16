# frozen_string_literal: true

ENV['BENCHMARK'] = 'true'

require 'spec_helper'
require 'benchmark/ips'
require 'benchmark/memory'
require 'benchmark'
require 'memory_profiler'

require 'rails'
require 'active_support/json'
require 'active_support/core_ext/time/zones'
require 'oj_serializers/compat'

Time.zone = 'UTC'

Dir[Pathname.new(__dir__).join('support/**/*.rb')].sort.each { |f| require f }

require 'singed'
Singed.output_directory = 'benchmarks/flamegraphs'
