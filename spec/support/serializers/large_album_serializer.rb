# frozen_string_literal: true

require_relative 'album_serializer'

class LargeAlbumSerializer < AlbumSerializer
  attribute :year do
    "2021"
  end

  attribute :day do
    23
  end

  attribute :month do
    "March"
  end

  attribute :band do
    "Unknown"
  end

  attribute :label do
    "Label"
  end

  attribute :producer do
    "Producer"
  end
end
