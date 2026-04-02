# frozen_string_literal: true

# Standalone benchmark runner for JSON serialization performance.
#
# Usage:
#   ruby benchmarks/runner.rb
#   ruby --yjit benchmarks/runner.rb
#
# Results are written as JSON to benchmarks/results/json_<yjit_status>.json

require 'bundler/setup'
require 'json'

BACKEND = 'json'
YJIT_ENABLED = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?

ENV['RACK_ENV'] = 'production'
ENV['BENCHMARK'] = 'true'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/time/zones'

Time.zone = 'UTC'

# Load json_serializers
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'json_serializers'

puts "Backend: json (Ruby's built-in JSON gem)"
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "YJIT: #{YJIT_ENABLED}"
puts "JSON gem: #{JSON::VERSION}" if defined?(JSON::VERSION)
puts

# Load models and serializers
require 'mongoid'
Mongoid.configure do |config|
  config.clients.merge!(
    default: { hosts: ['localhost:27017'], database: 'json_serializers_bench', options: { server_selection_timeout: 1 } },
  )
end

require File.expand_path('../spec/support/models/album', __dir__)
require File.expand_path('../spec/support/serializers/album_serializer', __dir__)

require 'benchmark/ips'

# Prepare test data
album = Album.abraxas
albums_100 = 100.times.map { Album.abraxas }
albums_1000 = 1000.times.map { Album.abraxas }

# Warm up
AlbumSerializer.one_as_hash(album)
AlbumSerializer.many_as_hash(albums_100)

# Verify correctness
hash_output = JSON.generate(AlbumSerializer.one_as_hash(album))
parsed_hash = JSON.parse(hash_output)

puts "Serializing album with #{album.songs.length} songs"
puts "=" * 60

# Collect results using benchmark-ips
class ResultCollector
  attr_reader :results

  def initialize
    @results = []
  end

  def run(scenarios)
    scenarios.each do |label, block|
      report = Benchmark.ips do |x|
        x.config(time: 3, warmup: 1)
        x.report(label, &block)
      end

      entry = report.entries.first
      @results << {
        name: entry.label,
        ips: entry.ips.round(1),
        stddev_pct: (entry.error_percentage || 0).round(2),
      }
    end
  end
end

collector = ResultCollector.new

# Define benchmark scenarios
scenarios = {}

scenarios['one object (as_hash + JSON.generate)'] = -> {
  JSON.generate(AlbumSerializer.one_as_hash(album))
}
scenarios['100 albums (as_hash + JSON.generate)'] = -> {
  JSON.generate(AlbumSerializer.many_as_hash(albums_100))
}
scenarios['1000 albums (as_hash + JSON.generate)'] = -> {
  JSON.generate(AlbumSerializer.many_as_hash(albums_1000))
}

collector.run(scenarios)

# Also run a combined comparison for display
puts
puts "=" * 60
puts "Combined comparison"
puts "=" * 60

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)
  scenarios.each { |label, block| x.report(label, &block) }
  x.compare!
end

# Save results
yjit_label = YJIT_ENABLED ? 'yjit' : 'no_yjit'
output_file = File.expand_path("results/#{BACKEND}_#{yjit_label}.json", __dir__)

result_data = {
  metadata: {
    ruby_version: RUBY_VERSION,
    ruby_platform: RUBY_PLATFORM,
    yjit: YJIT_ENABLED,
    backend: BACKEND,
    oj_version: nil,
    json_version: defined?(JSON::VERSION) ? JSON::VERSION : nil,
    timestamp: Time.now.iso8601,
  },
  results: collector.results,
}

File.write(output_file, JSON.pretty_generate(result_data))
puts
puts "Results saved to #{output_file}"
