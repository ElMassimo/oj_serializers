# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'
require 'support/models/sql'

class SnakeAlbumSerializer < AlbumSerializer
  transform_keys :underscore
  sort_attributes_by :name
end

RSpec.describe 'transform_keys' do
  let!(:game) { Game.example }
  let(:album) { Album.abraxas }

  before do
    allow_any_instance_of(AlbumSerializer).to receive(:other_songs) { album.songs }
  end

  it 'should not transform keys unless requested' do
    expect_parsed_json(GameSerializer.one(game)).to have_attributes(
      keys: %i[name high_score score best_player players],
    )
  end

  it 'should transform keys using camel case' do
    expect_parsed_json(AlbumSerializer.one(album)).to have_attributes(
      keys: %i[name genres release songs otherSongs],
    )
  end

  it 'should transform keys using snake case' do
    expect_parsed_json(SnakeAlbumSerializer.one(album)).to have_attributes(
      keys: %i[genres name other_songs release songs],
    )
  end
end
