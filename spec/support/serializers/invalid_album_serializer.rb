# frozen_string_literal: true

class InvalidAlbumSerializer < JsonSerializer
  attributes :release

  def release
    album.release_date.strftime('%B %d, %Y')
  end
end
