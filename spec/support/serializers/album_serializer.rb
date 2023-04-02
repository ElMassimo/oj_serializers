# frozen_string_literal: true

require_relative 'song_serializer'

class AlbumSerializer < Oj::Serializer
  transform_keys :camelize

  mongo_attributes(
    :id,
    :name,
    genres: {type: :string},
  )

  attribute if: -> { album.released? }
  def release
    album.release_date.strftime('%B %d, %Y')
  end

  attribute if: -> { special? }, as: :special
  def special?
    memo.fetch(:special) { options[:special] }
  end

  has_many :songs, serializer: SongSerializer
  has_many :other_songs, serializer: SongSerializer, if: -> { other_songs.present? }

  def other_songs
    []
  end
end
