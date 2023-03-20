# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :development do
  gem 'rubocop'
end

group :development, :test do
  gem 'active_model_serializers', '~> 0.8'
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'blueprinter', '~> 0.8'
  gem 'memory_profiler'
  gem 'mongoid'
  gem 'pry-byebug', '~> 3.9'
  gem 'rails' unless ENV['NO_RAILS']
  gem 'rake', '~> 13.0'
  gem 'rspec-rails', '~> 4.0'
  gem 'simplecov', '< 0.18'
  gem 'singed'
  gem 'sqlite3'
end
