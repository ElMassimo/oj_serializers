# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'
require 'active_model_serializers'

class AmsAlbumSerializer < ActiveModel::Serializer
  attributes(
    :name,
    :genres,
    :release,
    :songs,
  )

  def release
    object.release_date.strftime('%B %d, %Y')
  end

  # Mixing new serializers in old serializers
  def songs
    SongSerializer.many(object.songs)
  end
end

class OjAlbumSerializer < Oj::Serializer
  object_as :album

  ams_attributes(
    :name,
    :genres,
    :release,
    :songs,
  )

  def release
    album.release_date.strftime('%B %d, %Y')
  end

  # Mixing new serializers in old serializers
  def songs
    SongSerializer.many(album.songs)
  end
end

RSpec.describe 'Legacy Mode for Active Model Serializer', type: :serializer do
  let!(:album) { Album.abraxas }
  let!(:albums) { [album] }

  it 'should render new serializers in old serializers' do
    album_json = parse_json(AmsAlbumSerializer.new(album).to_json)

    expect(album_json[:songs].size).to eq album.songs.size
    expect(album_json[:songs][7]).to eq(
      track: 8,
      name: "Hope You're Feeling Better",
      composers: [
        'Rolie',
      ],
    )
  end

  it 'should render just like AMS' do
    expect_parsed_json(OjAlbumSerializer.one(album)).to eq parse_json(AmsAlbumSerializer.new(album).to_json)
  end
end
