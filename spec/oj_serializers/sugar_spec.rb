# frozen_string_literal: true

require 'spec_helper'
require 'rails/all'
require 'rspec/rails'

require 'support/controllers/albums_controller'

RSpec.describe AlbumsController, type: :controller do
  before(:all) do
    Rails.application.quick_setup
  end

  it 'should be able to use serializer options and legacy serializers' do
    get :list
    albums = parse_json[:albums]
    expect(albums.size).to eq 3

    get :show
    album = parse_json
    songs = album[:songs]
    expect(album).to include(
      name: 'Abraxas',
      release: 'September 23, 1970',
      genres: ['Pyschodelic Rock', 'Blues Rock', 'Jazz Fusion', 'Latin Rock'],
      special: true,
    )
    expect(album.except(:special)).to eq albums.first
    expect(songs.size).to eq 9
    expect(songs.second).to eq(
      track: 2,
      name: 'Black Magic Woman / Gypsy Queen',
      composers: ['Peter Green', 'Gábor Szabó'],
    )

    get :legacy_list
    legacy_albums = parse_json[:albums]
    expect(legacy_albums.map { |a| a.except(:special) }).to eq albums

    get :legacy_show
    legacy_album = parse_json
    expect(legacy_album).to eq album
  end
end
