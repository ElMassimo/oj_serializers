# frozen_string_literal: true

require_relative 'song_serializer'

class AlbumSerializer < Oj::Serializer
  mongo_attributes(
    :id,
  )

  raw_attributes(
    :name
  )

  object_attributes(
    :genres
  )

  has_many :songs, serializer: SongSerializer

  attribute \
  def release
    album.release_date.strftime('%B %d, %Y')
  end
end
