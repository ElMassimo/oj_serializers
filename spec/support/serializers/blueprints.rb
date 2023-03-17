# frozen_string_literal: true

require 'blueprinter'
require 'oj_serializers/compat'

Blueprinter.configure do |config|
  config.sort_fields_by = :definition
end

class SongBlueprint < Blueprinter::Base
  field :id, if: ->(_, song, _) { !song.new_record? }

  fields(
    :track,
    :name,
  )

  field :composers do |song|
    song.composer&.split(', ')
  end
end

class AlbumBlueprint < Blueprinter::Base
  field :id, if: ->(_, album, _) { !album.new_record? }

  fields(
    :name,
    :genres,
  )

  field :release, if: ->(_field_name, album, options) { album.released? } do |album|
    album.release_date.strftime('%B %d, %Y')
  end

  field :special, if: ->(_, _, options) { options[:special] } do |_, options|
    options[:special]
  end

  association :songs, blueprint: SongBlueprint
  association :other_songs, blueprint: SongBlueprint, if: ->(_, _, _) { false } do
    []
  end
end

class ModelBlueprint < Blueprinter::Base
  fields(
    :id,
    :name,
  )
end
