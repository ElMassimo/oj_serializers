# frozen_string_literal: true

require 'oj_serializers'
require 'active_model_serializers'

module OptionSerializer
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

  class Oj < Oj::Serializer
    attribute \
    def label
      @object.attributes['name']
    end

    attribute \
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
