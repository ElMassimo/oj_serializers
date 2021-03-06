# frozen_string_literal: true

require 'active_model_serializers'
require 'oj_serializers/compat'

# https://github.com/rails-api/active_model_serializers/blob/0-8-stable/README.md#1-disable-root-globally-for-all-or-per-class
ActiveSupport.on_load(:active_model_serializers) do
  # Disable for all serializers (except ArraySerializer)
  ActiveModel::Serializer.root = false

  # Disable for ArraySerializer
  ActiveModel::ArraySerializer.root = false
end

class LegacySongSerializer < ActiveModel::Serializer
  attributes(
    :track,
    :name,
    :composers,
  )

  def composers
    object.composer&.split(', ')
  end
end

class LegacyAlbumSerializer < ActiveModel::Serializer
  attributes(
    :name,
    :genres,
    :release,
    :special,
  )

  has_many :songs, serializer: LegacySongSerializer

  def release
    object.release_date.strftime('%B %d, %Y')
  end

  def special
    instance_options[:special] # Ensure the railtie does not affect the usual setup for AMS.
  end
end
