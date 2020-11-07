# frozen_string_literal: true

class AlbumsController < ApplicationController
  def index
    render json: { albums: AlbumSerializer.many(Album.all) }
  end

  def show
    render json: Album.first, serializer: AlbumSerializer
  end
end
