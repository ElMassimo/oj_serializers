# frozen_string_literal: true

class ModelSerializer < Oj::Serializer
  attributes(
    :id,
    :name,
  )
end
