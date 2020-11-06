# frozen_string_literal: true

require_relative 'application'

require 'support/models/album'
require 'support/serializers/album_serializer'
require 'support/serializers/legacy_serializers'

class AlbumsController < ApplicationController
  def show
    album = Album.abraxas
    render json: album, serializer: AlbumSerializer
  end

  def list
    albums = [Album.abraxas] * 3
    render json: albums, each_serializer: AlbumSerializer, root: :albums
  end

  def legacy_show
    album = Album.abraxas
    render json: album, serializer: LegacyAlbumSerializer
  end

  def legacy_list
    albums = [Album.abraxas] * 3
    render json: { albums: albums.map { |album| LegacyAlbumSerializer.new(album) } }
  end
end

Rails.application.routes.draw do
  resource :albums, only: [] do
    get :show, on: :collection
    get :list, on: :collection
    get :legacy_show, on: :collection
    get :legacy_list, on: :collection
  end
end
