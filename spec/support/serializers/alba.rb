# frozen_string_literal: true

require 'alba'

Alba.backend = :oj_rails
Alba.inflector = :active_support

class BaseAlba
  include Alba::Resource
  transform_keys :lower_camel
end

class SongAlba < BaseAlba
  attributes :id, if: proc { |song| !song.new_record? }

  attributes(
    :track,
    :name,
    :composers,
  )

  def composers(song)
    song.composer&.split(', ')
  end
end

class AlbumAlba < BaseAlba
  attributes :id, if: proc { |album| !album.new_record? }

  attributes(
    :name,
    :genres,
  )

  attributes :release, if: proc { |album| album.released? }
  def release(album)
    album.release_date.strftime('%B %d, %Y')
  end

  attributes :special, if: proc { params[:special] }
  def special(album)
    params[:special]
  end

  many :songs, resource: SongAlba
  many :other_songs, resource: SongAlba, if: proc { |album| album.other_songs.present? }
end

class ModelAlba < BaseAlba
  attributes(
    :id,
    :name,
  )
end
