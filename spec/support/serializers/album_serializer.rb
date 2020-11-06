# frozen_string_literal: true

require_relative 'song_serializer'

class AlbumSerializer < Oj::Serializer
  mongo_attributes(
    :id,
    :name,
    :genres,
  )

  has_many :songs, serializer: SongSerializer

  attribute \
  def release
    album.release_date.strftime('%B %d, %Y')
  end, if: -> { album.released? }

  attribute \
  def special
    special?
  end, if: -> { special? }

  def special?
    memo.fetch(:special) { options[:special] }
  end
end
