# frozen_string_literal: true

class InvalidAlbumSerializer < Oj::Serializer
  attributes :release

  def release
    album.release_date.strftime('%B %d, %Y')
  end
end
