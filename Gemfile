# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in oj_serializers.gemspec
gemspec

gem 'rake', '~> 12.0'

group :development do
  gem 'pry-byebug'
  gem 'rubocop'
end

group :test do
  gem 'active_model_serializers', '~> 0.8'
  gem 'activerecord'
  gem 'mongoid'
  gem 'rspec', '~> 3.0'
  gem 'rspec-rails'
  gem 'simplecov', '< 0.18'
  gem 'sqlite3'
end

group :performance do
  gem 'benchmark-ips'
  gem 'memory_profiler'
end
