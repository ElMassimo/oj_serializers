# frozen_string_literal: true

class SongSerializer < BaseSerializer
  attributes(
    :id,
    :track,
    :name,
  )

  serialize
  def composers
    song.composer&.split(', ')
  end
end
