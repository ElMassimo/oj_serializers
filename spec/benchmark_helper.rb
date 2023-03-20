# frozen_string_literal: true

ENV['BENCHMARK'] = 'true'

require 'spec_helper'
require 'benchmark/ips'
require 'benchmark/memory'
require 'benchmark'
require 'memory_profiler'

require 'rails'
require 'active_support/json'
require 'oj_serializers/compat'

Dir[Pathname.new(__dir__).join('support/**/*.rb')].sort.each { |f| require f }

require 'singed'
Singed.output_directory = 'benchmarks/flamegraphs'
