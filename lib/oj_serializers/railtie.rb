# frozen_string_literal: true

require 'rails/railtie'
require 'action_controller'
require 'action_controller/railtie'

require 'oj_serializers/controller_serialization'

# Internal: Allows to efficiently use `render json:` with Oj::Serializer.
class OjSerializers::Railtie < Rails::Railtie
  initializer 'oj_serializers.action_controller' do
    ActiveSupport.on_load(:action_controller) do
      include(OjSerializers::ControllerSerialization)
    end
  end
end
