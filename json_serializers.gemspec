# frozen_string_literal: true

require_relative 'lib/json_serializers/version'

Gem::Specification.new do |spec|
  spec.name          = 'json_serializers'
  spec.version       = JsonSerializers::VERSION
  spec.authors       = ['Maximo Mussini']
  spec.email         = ['maximomussini@gmail.com']

  spec.summary       = 'A lighter JSON serializer for Ruby Objects in Rails. Easily migrate away from Active Model Serializers.'
  spec.description   = 'json_serializers minimizes object allocations for fast JSON serialization, providing a similar API to Active Model Serializers.'
  spec.homepage      = 'https://github.com/ElMassimo/json_serializers'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ElMassimo/json_serializers'
  spec.metadata['changelog_uri'] = 'https://github.com/ElMassimo/json_serializers/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.glob('{lib}/**/*.rb') + %w[README.md CHANGELOG.md]
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
