# frozen_string_literal: true

require 'active_model_serializers'

# Extensions: To ensure JsonStringEncoder can process ActiveModel::Serializer
# as well.
class ActiveModel::Serializer
  # JsonStringEncoder: Used internally to write a single object to JSON.
  def self.one(object, options = nil)
    new(object, options)
  end

  # JsonStringEncoder: Used internally to write an array of objects to JSON.
  def self.many(array, options = nil)
    array.map { |object| new(object, options) }
  end

  # OjSerializer: Used internally to write a single object association in :hash mode.
  #
  # Returns nothing.
  def self.one_as_hash(object, options = nil)
    new(object)
  end

  # OjSerializer: Used internally to write an association in :hash mode.
  #
  # Returns nothing.
  def self.many_as_hash(array, options = nil)
    array.map { |object| new(object) }
  end

  # OjSerializer: Used internally to write a single object association in :json mode.
  #
  # Returns nothing.
  def self.write_one(writer, object, options = nil)
    writer.push_value(new(object))
  end

  # OjSerializer: Used internally to write an association in :json mode.
  #
  # Returns nothing.
  def self.write_many(writer, array, options = nil)
    writer.push_array
    array.each do |object|
      write_one(writer, object)
    end
    writer.pop
  end

  module OjOptionsCompat
    def add_attribute(value_from, key: nil, **options)
      options[:as] ||= key if key

      if (unless_proc = options.delete(:unless))
        options[:if] = -> { !instance_exec(&unless_proc) }
      end

      super(value_from, **options)
    end
  end
end

require 'oj_serializers'
require 'oj_serializers/sugar'

Oj::Serializer.singleton_class.prepend(ActiveModel::Serializer::OjOptionsCompat)
