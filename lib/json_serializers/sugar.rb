# frozen_string_literal: true

require 'rails/railtie'
require 'action_controller'
require 'action_controller/railtie'

require 'json_serializers'
require 'json_serializers/controller_serialization'

# Internal: Allows to pass JsonSerializer as options in `render`.
class JsonSerializers::Railtie < Rails::Railtie
  initializer 'json_serializers.action_controller' do
    ActiveSupport.on_load(:action_controller) do
      include(JsonSerializers::ControllerSerialization)
    end
  end
end
