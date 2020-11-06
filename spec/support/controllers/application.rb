# frozen_string_literal: true

require 'rails'
require 'action_pack'
require 'action_controller/railtie'
require 'support/models/sql'

class MusicApplication < Rails::Application
  def quick_setup
    initializers.find { |i| i.name == 'active_model_serializers.action_controller' }.run
    initializers.find { |i| i.name == 'oj_serializers.action_controller' }.run
  end
end

class ApplicationController < ActionController::Base
end

require 'oj_serializers/sugar'
