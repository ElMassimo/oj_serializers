# frozen_string_literal: true

require 'oj_serializers'
require 'active_model_serializers'
require 'blueprinter'
require 'panko_serializer'
require_relative 'alba'

module OptionSerializer
  class Alba
    include ::Alba::Resource

    attribute :label do |object|
      object.attributes['name']
    end

    attribute :value do |object|
      object.attributes['_id']
    end
  end

  class AMS < ActiveModel::Serializer
    attributes(
      :label,
      :value,
    )

    def label
      object.attributes['name']
    end

    def value
      object.attributes['_id']
    end
  end

  class Blueprinter < Blueprinter::Base
    field :label do |object|
      object.attributes['name']
    end

    field :value do |object|
      object.attributes['_id']
    end
  end

  class Oj < Oj::Serializer
    attr
    def label
      @object.attributes['name']
    end

    attr
    def value
      @object.attributes['_id']
    end
  end

  class Panko < Panko::Serializer
    attributes(:label, :value)

    def label
      @object.attributes['name']
    end

    def value
      @object.attributes['_id']
    end
  end

  def self.write_models(models)
    writer = ::Oj::StringWriter.new(mode: :wab)

    writer.push_array

    models.each do |model|
      writer.push_object
      writer.push_value(model.attributes['name'], 'label')
      writer.push_value(model.attributes['_id'], 'value')
      writer.pop
    end
    writer.pop

    writer
  end

  def self.map_models(models)
    models.map do |model|
      { label: model.attributes['name'], value: model.attributes['_id'] }
    end
  end
end
