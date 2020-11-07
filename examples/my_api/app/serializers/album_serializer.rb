# frozen_string_literal: true

class AlbumSerializer < BaseSerializer
  attributes(
    :id,
    :name,
    :genres,
  )

  has_many :songs, serializer: SongSerializer

  attribute \
  def release
    album.release_date.strftime('%B %d, %Y')
  end, if: -> { album.released? }
end
