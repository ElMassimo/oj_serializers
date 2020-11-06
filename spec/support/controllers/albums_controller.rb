# frozen_string_literal: true

require 'oj_serializers/sugar'
require 'actionpack'

class AlbumsController < ActionController::Base
  def show
    album = Album.abraxas
    render json: album, serializer: AlbumSerializer
  end

  def index
    albums = [Album.abraxas]
    render json: albums, each_serializer: AlbumSerializer, root: :albums
  end
end
