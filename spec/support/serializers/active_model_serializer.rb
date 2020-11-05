# frozen_string_literal: true

require 'active_model_serializers'
require 'oj_serializers/compat'

class ActiveModelSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :name,
  )
end
