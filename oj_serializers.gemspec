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
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ElMassimo/oj_serializers'
  spec.metadata['changelog_uri'] = 'https://github.com/ElMassimo/oj_serializers/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.glob('{lib}/**/*.rb') + %w[README.md CHANGELOG.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'oj', '>= 3.14.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
