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
    # Returns a JSON string.
    #
    # NOTE: Unlike the default encoder, this one will use the `root` option
    # regardless of whether a serializer is specified or not.
    def encode_to_json(object, root: nil, serializer: nil, each_serializer: nil, **extras)
      # NOTE: Serializers may override `new_json_writer` to modify the behavior.
      writer = (serializer || each_serializer || OjSerializers::Serializer).send(:new_json_writer)

      if root
        writer.push_object
        writer.push_key(root.to_s)
      end

      if serializer
        serializer.write_one(writer, object, extras)
      elsif each_serializer
        each_serializer.write_many(writer, object, extras)
      elsif object.is_a?(String)
        return object unless root

        writer.push_json(object)
      else
        writer.push_value(object)
      end

      writer.pop if root

      writer.to_json
    end

    # Allows to detect misusage of the options during development.
    if OjSerializers::Serializer::DEV_MODE
      alias actual_encode_to_json encode_to_json
      def encode_to_json(object, root: nil, serializer: nil, each_serializer: nil, **extras)
        if serializer && serializer < OjSerializers::Serializer
          raise ArgumentError, 'You must use `each_serializer` when serializing collections' if object.respond_to?(:each)
        end
        if each_serializer && each_serializer < OjSerializers::Serializer
          raise ArgumentError, 'You must use `serializer` when serializing a single object' unless object.respond_to?(:each)
        end
        actual_encode_to_json(object, root: root, serializer: serializer, each_serializer: each_serializer, **extras)
      end
    end
  end
end
