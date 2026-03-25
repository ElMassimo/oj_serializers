# frozen_string_literal: true

require 'spec_helper'

require 'support/models/album'
require 'support/serializers/active_model_serializer'

class CompatSerializer < JsonSerializer
  has_one :item, key: :album, serializer: ActiveModelSerializer
  has_many :items, serializer: ActiveModelSerializer, unless: -> { options[:skip_collection] }
end

RSpec.describe 'AMS Compat', type: :serializer do
  def expect_encoded_json(object)
    expect(JSON.generate(object))
  end

  it 'can use ams serializer in associations' do
    album = Album.abraxas.tap { |a| a.id = 1 }
    object = double('compat', item: album, items: [album, album])
    attrs = { id: 1, name: 'Abraxas' }

    expect_encoded_json(CompatSerializer.one(object)).to eq({
      album: attrs,
      items: [attrs, attrs],
    }.to_json)

    expect_encoded_json(CompatSerializer.one(object, skip_collection: true)).to eq({
      album: attrs,
    }.to_json)
  end
end
