# frozen_string_literal: true

require 'json_serializers/json_string_encoder'

# Internal: Allows to pass JsonSerializer as options in `render`.
module JsonSerializers::ControllerSerialization
  extend ActiveSupport::Concern
  include ActionController::Renderers

  # Internal: Allows to use JsonSerializer as `serializer` and `each_serializer`
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
    define_method renderer_method do |resource, options = {}|
      serializer_class = options[:serializer] || options[:each_serializer]
      if serializer_class && serializer_class < JsonSerializers::Serializer
        super(JsonSerializers::JsonStringEncoder.encode_to_json(resource, **options), options.except(:root, :serializer, :each_serializer))
      else
        super(resource, options)
      end
    end
  end
end
