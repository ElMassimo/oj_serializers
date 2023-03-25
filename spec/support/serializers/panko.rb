# frozen_string_literal: true

require 'panko_serializer'

Mongoid::Criteria.prepend Module.new {
  def track
  end
}

Album.prepend Module.new {
  def other_songs
    []
  end
}

class SongPanko < Panko::Serializer
  attributes(
    :id,
    :track,
    :name,
    :composers,
  )

  def id
    object.id unless object.new_record?
  end

  def composers
    object.composer&.split(', ')
  end

  # NOTE: Panko does not have a way to conditionally not include an attribute.
  def self.filters_for(context, scope)
    {
      except: [:id]
    }
  end
end

class AlbumPanko < Panko::Serializer
  attributes
  def id
    object.id unless object.new_record?
  end

  attributes(
    :name,
    :genres,
    :release,
    :special
  )

  def release
    object.release_date.strftime('%B %d, %Y') if object.released?
  end

  def special
    context[:special] if context
  end

  has_many :songs, serializer: SongPanko
  has_many :other_songs, serializer: SongPanko

  def other_songs
    other_songs if other_songs.present?
  end

  # NOTE: Panko does not have a way to conditionally not include an attribute.
  def self.filters_for(context, scope)
    {
      except: [:id, :other_songs]
    }
  end
end

class ModelPanko < Panko::Serializer
  attributes(
    :id,
    :name,
  )
end
