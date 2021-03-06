# frozen_string_literal: true

require 'active_model_serializers'

# Extensions: To ensure JsonStringEncoder can process ActiveModel::Serializer
# as well.
class ActiveModel::Serializer
  # JsonStringEncoder: Used internally to write a single object to JSON.
  #
  # Returns nothing.
  def self.write_one(writer, object, options)
    writer.push_value(new(object, options))
  end

  # JsonStringEncoder: Used internally to write an array of objects to JSON.
  #
  # Returns nothing.
  def self.write_many(writer, array, options)
    writer.push_array
    array.each do |object|
      write_one(writer, object, options)
    end
    writer.pop
  end

  # JsonStringEncoder: Used internally to instantiate an Oj::StringWriter.
  #
  # Returns an Oj::StringWriter.
  def self.new_json_writer
    OjSerializers::Serializer.send(:new_json_writer)
  end
end

require 'oj_serializers'
require 'oj_serializers/sugar'
