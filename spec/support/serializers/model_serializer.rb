# frozen_string_literal: true

class ModelSerializer < Oj::Serializer
  # NOTE: attributes is not recommended, it's better to be explicit about the
  # strategy.
  attributes(
    :id,
    :name,
  )
end
