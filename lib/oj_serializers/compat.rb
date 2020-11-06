# frozen_string_literal: true

begin
  require 'active_model_serializers'
rescue Exception => error
  raise 'Since `active_model_serializers` is not available, you should `require "oj_serializers/sugar"` instead.'
  raise error
end

# Extensions: To ensure JsonStringEncoder can process ActiveModel::Serializer
# as well.
class ActiveModel::Serializer
  # JsonStringEncoder: Used internally to write a single object to JSON.
  def self.write_one(writer, object, options)
    writer.push_value(new(object, options))
  end

  # JsonStringEncoder: Used internally to write an array of objects to JSON.
  def self.write_many(writer, array, options)
    writer.push_array
    array.each do |object|
      write_one(writer, object, options)
    end
    writer.pop
  end

  # JsonStringEncoder: Used internally to instantiate an Oj::StringWriter.
  def self.new_json_writer
    OjSerializers::Serializer.send(:new_json_writer)
  end
end

require 'oj_serializers'
require 'oj_serializers/sugar'
