# frozen_string_literal: true

# Standalone benchmark runner for comparing oj vs JSON gem backends.
#
# Usage:
#   ruby benchmarks/runner.rb --backend=oj
#   ruby benchmarks/runner.rb --backend=json
#   ruby --yjit benchmarks/runner.rb --backend=oj
#   ruby --yjit benchmarks/runner.rb --backend=json
#
# Results are written as JSON to benchmarks/results/<backend>_<yjit_status>.json

require 'bundler/setup'
require 'json'

BACKEND = ARGV.find { |a| a.start_with?('--backend=') }&.split('=', 2)&.last || 'oj'
YJIT_ENABLED = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?

# Block oj from loading when testing the json backend.
if BACKEND == 'json'
  module OjBlocker
    def require(name)
      if name == 'oj'
        raise LoadError, "oj is intentionally blocked for json-backend benchmark"
      end
      super
    end
  end
  Object.prepend(OjBlocker)
end

ENV['RACK_ENV'] = 'production'
ENV['BENCHMARK'] = 'true'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/time/zones'

Time.zone = 'UTC'

# Load oj_serializers (will use JsonWriter fallback when oj is blocked)
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'oj_serializers'

# Verify backend isolation
if BACKEND == 'json'
  if defined?(Oj::StringWriter)
    abort "ERROR: Oj C extension is loaded but should not be for json backend!"
  end
  puts "Backend: json (Ruby's built-in JSON gem)"
else
  unless defined?(Oj::StringWriter)
    abort "ERROR: Oj C extension is not loaded for oj backend!"
  end
  puts "Backend: oj (#{Oj::VERSION})"
end

puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "YJIT: #{YJIT_ENABLED}"
puts "JSON gem: #{JSON::VERSION}" if defined?(JSON::VERSION)
puts

# Load models and serializers
require 'mongoid'
Mongoid.configure do |config|
  config.clients.merge!(
    default: { hosts: ['localhost:27017'], database: 'oj_serializers_bench', options: { server_selection_timeout: 1 } },
  )
end

# Load only the models and serializers needed for the album benchmark.
# sql.rb and others reference Oj::Serializer which isn't available without oj.
require File.expand_path('../spec/support/models/album', __dir__)
require File.expand_path('../spec/support/serializers/album_serializer', __dir__)

require 'benchmark/ips'

# Prepare test data
album = Album.abraxas
albums_100 = 100.times.map { Album.abraxas }
albums_1000 = 1000.times.map { Album.abraxas }

# Warm up
AlbumSerializer.one_as_json(album)
AlbumSerializer.one_as_hash(album)
AlbumSerializer.many_as_json(albums_100)
AlbumSerializer.many_as_hash(albums_100)

# Verify correctness
json_output = AlbumSerializer.one_as_json(album).to_s
hash_output = JSON.generate(AlbumSerializer.one_as_hash(album))
parsed_json = JSON.parse(json_output)
parsed_hash = JSON.parse(hash_output)

unless parsed_json == parsed_hash
  warn "WARNING: as_json and as_hash outputs differ!"
  warn "as_json keys: #{parsed_json.keys}"
  warn "as_hash keys: #{parsed_hash.keys}"
end

puts "Serializing album with #{album.songs.length} songs"
puts "=" * 60

results = []

# Helper to capture benchmark-ips results
def run_benchmark(label, &block)
  report_data = nil
  Benchmark.ips do |x|
    x.config(time: 3, warmup: 1)
    x.report(label, &block)
    x.compare!
  end
end

# Collect results using benchmark-ips with a custom reporter
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

if BACKEND == 'oj'
  scenarios['one object (as_json + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.one_as_json(album))
  }
  scenarios['one object (as_hash + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.one_as_hash(album))
  }
  scenarios['100 albums (as_json + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.many_as_json(albums_100))
  }
  scenarios['100 albums (as_hash + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.many_as_hash(albums_100))
  }
  scenarios['1000 albums (as_json + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.many_as_json(albums_1000))
  }
  scenarios['1000 albums (as_hash + Oj.dump)'] = -> {
    Oj.dump(AlbumSerializer.many_as_hash(albums_1000))
  }
else
  scenarios['one object (as_json + JSON.generate)'] = -> {
    AlbumSerializer.one_as_json(album).to_s
  }
  scenarios['one object (as_hash + JSON.generate)'] = -> {
    JSON.generate(AlbumSerializer.one_as_hash(album))
  }
  scenarios['100 albums (as_json + JSON.generate)'] = -> {
    AlbumSerializer.many_as_json(albums_100).to_s
  }
  scenarios['100 albums (as_hash + JSON.generate)'] = -> {
    JSON.generate(AlbumSerializer.many_as_hash(albums_100))
  }
  scenarios['1000 albums (as_json + JSON.generate)'] = -> {
    AlbumSerializer.many_as_json(albums_1000).to_s
  }
  scenarios['1000 albums (as_hash + JSON.generate)'] = -> {
    JSON.generate(AlbumSerializer.many_as_hash(albums_1000))
  }
end

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
    oj_version: defined?(Oj::VERSION) ? Oj::VERSION : nil,
    json_version: defined?(JSON::VERSION) ? JSON::VERSION : nil,
    timestamp: Time.now.iso8601,
  },
  results: collector.results,
}

File.write(output_file, JSON.pretty_generate(result_data))
puts
puts "Results saved to #{output_file}"
