# frozen_string_literal: true

require_relative 'song_serializer'

class AlbumSerializer < Oj::Serializer
  identifier

  mongo_attributes(
    :id,
    :name,
    :genres,
  )

  serialize if: -> { album.released? }
  def release
    album.release_date.strftime('%B %d, %Y')
  end

  serialize if: -> { special? }, as: :specials
  def special?
    memo.fetch(:special) { options[:special] }
  end

  has_many :songs, serializer: SongSerializer
  has_many :other_songs, serializer: SongSerializer, if: -> { other_songs.present? }

  def other_songs
    []
  end
end
