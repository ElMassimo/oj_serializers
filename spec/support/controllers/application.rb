# frozen_string_literal: true

require 'rails'
require 'action_pack'
require 'action_controller/railtie'
require 'support/models/sql'

class MusicApplication < Rails::Application
  def quick_setup
    ams_init = initializers.find { |i| i.name == 'active_model_serializers.action_controller' }
    oj_init = initializers.find { |i| i.name == 'oj_serializers.action_controller' }

    if ams_init && oj_init
      ams_init.run
      oj_init.run
    else
      # If initializers weren't registered (e.g. due to load order), manually
      # include the modules needed for the controller tests.
      require 'action_controller/serialization'
      ApplicationController.include(::ActionController::Serialization)
      ApplicationController.include(OjSerializers::ControllerSerialization)
    end
  end
end

class ApplicationController < ActionController::Base
end

require 'oj_serializers/sugar'
