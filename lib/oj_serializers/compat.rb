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
end

require 'oj_serializers'
require 'oj_serializers/sugar'
