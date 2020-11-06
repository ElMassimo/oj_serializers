# frozen_string_literal: true

class ModelSerializer < Oj::Serializer
  # NOTE: ams_attributes is not recommended, it's better to be explicit about
  # the strategy.
  ams_attributes(
    :id,
    :name,
  )
end
