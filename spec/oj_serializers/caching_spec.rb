# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'

class CachedAlbumSerializer < AlbumSerializer
  cached_with_key -> (album) { [album.name] }
end

RSpec.describe 'Caching', type: :serializer do
  let!(:album) { Album.abraxas }
  let!(:albums) { [album] * 5 }

  it 'should reuse the cache effectively' do
    expect(CachedAlbumSerializer.one(album).to_json).to eq AlbumSerializer.one(album).to_json

    expect_any_instance_of(Album).not_to receive(:release_date)
    expect(JSON.parse(CachedAlbumSerializer.one(album))['name']).to eq album.name
    expect(JSON.parse(CachedAlbumSerializer.many(albums)).first['name']).to eq album.name
  end
end
