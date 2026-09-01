# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'

class CachedSongSerializer < SongSerializer
  cached_with_options(expires_in: 1.minute)
end

class CachedAlbumSerializer < AlbumSerializer
  cached_with_key ->(album) { [album.name] }

  has_many :songs, serializer: CachedSongSerializer
end

RSpec.describe 'Caching', type: :serializer do
  let!(:album) { Album.abraxas }
  let!(:other_album) { Album.new(id: 1, name: 'Amigos', release_date: Date.new(1976, 3, 26)) }
  let!(:albums) { [album, other_album] }

  before do
    # NOTE: Uncomment to debug test failures.
    # OjSerializers.configuration.cache.logger = ActiveSupport::Logger.new(STDOUT)
  end

  it 'should reuse the cache effectively' do
    allow_any_instance_of(Mongoid::Document).to receive(:new_record?).and_return(false)

    attrs = parse_json(AlbumSerializer.one(album))
    expect(attrs).to include(name: album.name)
    other_attrs = parse_json(AlbumSerializer.one(other_album))
    expect(other_attrs).to eq(id: 1, name: 'Amigos', release: 'March 26, 1976', genres: nil, songs: [])

    expect(album.songs.first).to receive(:composer).once.and_call_original
    expect_parsed_json(CachedSongSerializer.many(album.songs)).to eq attrs[:songs]

    expect(album.songs.first).not_to receive(:composer)
    expect(album).to receive(:release_date).once.and_call_original
    expect(other_album).to receive(:release_date).once.and_call_original
    expect_parsed_json(CachedAlbumSerializer.one(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one(other_album)).to eq other_attrs

    expect_any_instance_of(Album).not_to receive(:release_date)
    expect_parsed_json(CachedAlbumSerializer.one(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one(other_album)).to eq other_attrs
    expect_parsed_json(CachedAlbumSerializer.many(albums)).to eq [attrs, other_attrs]
  end

  it 'should reuse the cache effectively for JSON' do
    attrs = parse_json(AlbumSerializer.one_as_json(album))
    expect(attrs).to include(name: album.name)
    other_attrs = parse_json(AlbumSerializer.one_as_json(other_album))
    expect(other_attrs).to eq(name: 'Amigos', release: 'March 26, 1976', genres: nil, songs: [])

    expect(album).to receive(:release_date).once.and_call_original
    expect(other_album).to receive(:release_date).once.and_call_original
    expect_parsed_json(CachedAlbumSerializer.one_as_json(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one_as_json(other_album)).to eq other_attrs

    expect_any_instance_of(Album).not_to receive(:release_date)
    expect_parsed_json(CachedAlbumSerializer.one_as_json(album)).to eq attrs
    expect_parsed_json(CachedAlbumSerializer.one_as_json(other_album)).to eq other_attrs
    expect_parsed_json(CachedAlbumSerializer.many_as_json(albums)).to eq [attrs, other_attrs]
  end

  it 'should use correct cache options' do
    expect(OjSerializers).to receive(:configuration).at_least(1).and_return(OjSerializers::Config.new)
    attrs = parse_json(AlbumSerializer.one_as_json(album))
    expect(OjSerializers.configuration.cache).to receive(:fetch_multi).once.with(any_args, include(expires_in: 1.minute)).and_call_original
    expect_parsed_json(CachedAlbumSerializer.one_as_json(album)).to eq attrs
  end
end
