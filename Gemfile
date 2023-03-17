# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in oj_serializers.gemspec
gemspec

group :development do
  gem 'rubocop'
end

group :development, :test do
  gem 'actionpack'
  gem 'active_model_serializers', '~> 0.8'
  gem 'activerecord'
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'blueprinter', '~> 0.8'
  gem 'memory_profiler'
  gem 'mongoid'
  gem 'pry-byebug', '~> 3.9'
  gem 'railties'
  gem 'rake', '~> 13.0'
  gem 'rspec-rails', '~> 4.0'
  gem 'simplecov', '< 0.18'
  gem 'sqlite3'
end
