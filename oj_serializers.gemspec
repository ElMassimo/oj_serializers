# frozen_string_literal: true

require_relative 'lib/oj_serializers/version'

Gem::Specification.new do |spec|
  spec.name          = 'oj_serializers'
  spec.version       = OjSerializers::VERSION
  spec.authors       = ['Maximo Mussini']
  spec.email         = ['maximomussini@gmail.com']

  spec.summary       = 'A lighter JSON serializer for Ruby Objects in Rails. Easily migrate away from Active Model Serializers.'
  spec.description   = 'oj_serializers leverages the performance of the oj JSON serialization library, and minimizes object allocations, all while provding a similar API to Active Model Serializers.'
  spec.homepage      = 'https://github.com/ElMassimo/oj_serializers'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ElMassimo/oj_serializers'
  spec.metadata['changelog_uri'] = 'https://github.com/ElMassimo/oj_serializers/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.glob('{lib}/**/*.rb') + %w[README.md CHANGELOG.md]
  spec.require_paths = ['lib']

  rails_versions = '>= 4.0'

  spec.add_dependency 'oj', '>= 3.14.0'

  spec.add_development_dependency 'actionpack', rails_versions
  spec.add_development_dependency 'active_model_serializers', '~> 0.8'
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'blueprinter', '~> 0.8'
  spec.add_development_dependency 'memory_profiler'
  spec.add_development_dependency 'mongoid'
  spec.add_development_dependency 'pry-byebug', '~> 3.9'
  spec.add_development_dependency 'railties', rails_versions
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec-rails', '~> 4.0'
  spec.add_development_dependency 'simplecov', '< 0.18'
  spec.add_development_dependency 'sqlite3'
end
