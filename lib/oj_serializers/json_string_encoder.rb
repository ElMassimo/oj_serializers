# frozen_string_literal: true

# Public: Contains utility functions to render objects to JSON.
#
# Useful to instantiate a single `JsonWriter` when rendering new serializers.
module OjSerializers::JsonStringEncoder
  class << self
    # Public: Allows to use Oj::Serializer in `serializer` and `each_serializer`
    # as with ActiveModelSerializers.
    #   render json: items, each_serializer: ItemSerializer
    #   render json: item, serializer: ItemSerializer
    #
    # NOTE: Unlike the default encoder, this one will use the `root` option
    # regardless of whether a serializer is specified or not.
    #
    # Returns a JSON string.
    def encode_to_json(object, root: nil, serializer: nil, each_serializer: nil, **options)
      result = if serializer
        serializer.one(object, options)
      elsif each_serializer
        each_serializer.many(object, options)
      elsif object.is_a?(String)
        OjSerializers::JsonValue.new(object)
      else
        object
      end
      Oj.dump(root ? {root => result} : result)
    end

    if OjSerializers::Serializer::DEV_MODE
      alias actual_encode_to_json encode_to_json
      # Internal: Allows to detect misusage of the options during development.
      def encode_to_json(object, root: nil, serializer: nil, each_serializer: nil, **options)
        if serializer && serializer < OjSerializers::Serializer
          raise ArgumentError, 'You must use `each_serializer` when serializing collections' if object.respond_to?(:map)
        end
        if each_serializer && each_serializer < OjSerializers::Serializer
          raise ArgumentError, 'You must use `serializer` when serializing a single object' unless object.respond_to?(:map)
        end
        actual_encode_to_json(object, root: root, serializer: serializer, each_serializer: each_serializer, **options)
      end
    end
  end
end
