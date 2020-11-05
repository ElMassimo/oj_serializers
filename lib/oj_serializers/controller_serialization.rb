# frozen_string_literal: true

require 'oj_serializers/json_string_encoder'

# Internal: Allows to efficiently use `render json:` with Oj::Serializer.
module OjSerializers::ControllerSerialization
  extend ActiveSupport::Concern
  include ActionController::Renderers

  # Internal: Allows to use Oj::Serializer as `serializer` and `each_serializer`
  # as with ActiveModelSerializers.
  #
  #   render json: items, each_serializer: ItemSerializer
  #   render json: item, serializer: ItemSerializer
  #
  # NOTE: In practice, it should be preferable to simply do:
  #
  #   render json: ItemSerializer.many(items)
  #   render json: ItemSerializer.one(item)
  #
  # which is more performant.
  %i[_render_option_json _render_with_renderer_json].each do |renderer_method|
    define_method renderer_method do |resource, **options|
      serializer_class = options[:serializer] || options[:each_serializer]
      if serializer_class && serializer_class < OjSerializers::Serializer
        super(JsonStringEncoder.encode_to_json(resource, options), options)
      else
        super(json_string, options)
      end
    end
  end
end
