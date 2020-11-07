# frozen_string_literal: true

class SongSerializer < Oj::Serializer
  mongo_attributes(
    :id,
    :track,
  )

  attributes(
    :name,
  )

  serializer_attributes(
    :composers,
  )

  def composers
    song.composer&.split(', ')
  end
end
