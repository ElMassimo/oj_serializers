# frozen_string_literal: true

# Orchestrator: runs benchmark configurations and generates charts.
#
# Usage:
#   ruby benchmarks/run_comparison.rb
#
# Spawns separate Ruby processes for each configuration to ensure clean state.

require 'json'

RUBY = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
RUNNER = File.expand_path('runner.rb', __dir__)
RESULTS_DIR = File.expand_path('results', __dir__)
CHART_GENERATOR = File.expand_path('generate_charts.rb', __dir__)

Dir.mkdir(RESULTS_DIR) unless Dir.exist?(RESULTS_DIR)

yjit_available = begin
  system(RUBY, '--yjit', '-e', 'exit(RubyVM::YJIT.enabled? ? 0 : 1)', out: File::NULL, err: File::NULL)
rescue StandardError
  false
end

configurations = [
  { backend: 'json', yjit: false, label: 'json (no YJIT)' },
]

if yjit_available
  configurations << { backend: 'json', yjit: true, label: 'json (YJIT)' }
else
  puts "Note: YJIT is not available in this Ruby build (#{RUBY_VERSION})"
  puts "      Skipping YJIT configurations."
  puts
end

configurations.each_with_index do |config, i|
  puts "=" * 60
  puts "[#{i + 1}/#{configurations.length}] Running: #{config[:label]}"
  puts "=" * 60
  puts

  cmd = [RUBY]
  cmd << '--yjit' if config[:yjit]
  cmd << '--disable-yjit' if !config[:yjit] && yjit_available
  cmd += [RUNNER, "--backend=#{config[:backend]}"]

  env = { 'BUNDLE_GEMFILE' => File.expand_path('../Gemfile', __dir__) }

  success = system(env, *cmd)

  unless success
    warn "WARNING: Benchmark failed for #{config[:label]} (exit code: #{$?.exitstatus})"
  end

  puts
end

# Generate charts
puts "=" * 60
puts "Generating comparison charts..."
puts "=" * 60

system(RUBY, CHART_GENERATOR)

puts
puts "Done! Results are in #{RESULTS_DIR}/"
