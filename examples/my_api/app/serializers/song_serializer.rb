# frozen_string_literal: true

class SongSerializer < BaseSerializer
  attributes(
    :id,
    :track,
    :name,
  )

  attribute
  def composers
    song.composer&.split(', ')
  end
end
