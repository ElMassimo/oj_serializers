# frozen_string_literal: true

Rails.application.routes.draw do
  get '/albums', controller: :albums, action: :index
  get '/album', controller: :albums, action: :show
end
