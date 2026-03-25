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
require 'json_serializers/compat'

Time.zone = 'UTC'

Dir[Pathname.new(__dir__).join('support/**/*.rb')].sort.each { |f| require f }

require 'singed'
Singed.output_directory = 'benchmarks/flamegraphs'

# Collect benchmark-ips results for chart generation.
BENCHMARK_RESULTS = {}

# Run a benchmark-ips section, collecting results for chart generation.
#
#   benchmark_section('AlbumSerializer: single model') do |x|
#     x.report('json_serializers') { ... }
#     x.report('panko') { ... }
#     x.compare!
#   end
def benchmark_section(name, time: 5, warmup: 2, &block)
  report = Benchmark.ips do |x|
    x.config(time: time, warmup: warmup)
    block.call(x)
  end

  BENCHMARK_RESULTS[name] = report.entries.map { |entry|
    {
      label: entry.label,
      ips: entry.ips.round(1),
      stddev_pct: (entry.error_percentage || 0).round(2),
    }
  }

  report
end

RSpec.configure do |config|
  config.after(:suite) do
    next if BENCHMARK_RESULTS.empty?

    results_dir = File.expand_path('../benchmarks/results', __dir__)
    Dir.mkdir(results_dir) unless Dir.exist?(results_dir)

    result_data = {
      metadata: {
        ruby_version: RUBY_VERSION,
        ruby_platform: RUBY_PLATFORM,
        yjit: defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enabled?) && RubyVM::YJIT.enabled?,
        json_version: defined?(JSON::VERSION) ? JSON::VERSION : nil,
        timestamp: Time.now.iso8601,
      },
      scenarios: BENCHMARK_RESULTS,
    }

    output_file = File.join(results_dir, 'frameworks.json')
    File.write(output_file, JSON.pretty_generate(result_data))
    puts "\nBenchmark results saved to #{output_file}"

    # Generate charts
    chart_generator = File.expand_path('../benchmarks/generate_framework_charts.rb', __dir__)
    if File.exist?(chart_generator)
      system(RbConfig.ruby, chart_generator)
    end
  end
end
