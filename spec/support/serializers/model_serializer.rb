# frozen_string_literal: true

class ModelSerializer < JsonSerializer
  attributes(
    :id,
    :name,
  )
end
