# frozen_string_literal: true

class SongSerializer < Oj::Serializer
  mongo_attributes(
    :id,
    :track,
  )

  attributes(
    :name,
  )

  attribute \
  def composers
    song.composer&.split(', ')
  end
end
