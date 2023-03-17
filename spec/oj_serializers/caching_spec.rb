# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'

class CachedSongSerializer < SongSerializer
  # cached
end

class CachedAlbumSerializer < AlbumSerializer
  # cached_with_key ->(album) { [album.name] }

  has_many :songs, serializer: CachedSongSerializer
end

RSpec.xdescribe 'Caching', type: :serializer do
  let!(:album) { Album.abraxas }
  let!(:other_album) { Album.new(name: 'Amigos', release_date: Date.new(1976, 3, 26)) }
  let!(:albums) { [album, other_album] }

  it 'should reuse the cache effectively' do
    attrs = parse_json(AlbumSerializer.one(album))
    expect(attrs).to include(name: album.name)
    other_attrs = parse_json(AlbumSerializer.one(other_album))
    expect(other_attrs).to eq(name: 'Amigos', release: 'March 26, 1976', genres: nil, songs: [])

    expect(album).to receive(:release_date).once.and_call_original
    expect(other_album).to receive(:release_date).once.and_call_original
    expect_parsed_json(CachedAlbumSerializer.one(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one(other_album)).to eq other_attrs

    expect_any_instance_of(Album).not_to receive(:release_date)
    expect_parsed_json(CachedAlbumSerializer.one(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one(other_album)).to eq other_attrs
    expect_parsed_json(CachedAlbumSerializer.many(albums)).to eq [attrs, other_attrs]
  end
end
