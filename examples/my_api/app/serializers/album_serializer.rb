# frozen_string_literal: true

class AlbumSerializer < BaseSerializer
  attributes(
    :id,
    :name,
    :genres,
  )

  attribute if: -> { album.released? }
  def release
    album.release_date.strftime('%B %d, %Y')
  end

  has_many :songs, serializer: SongSerializer
end
