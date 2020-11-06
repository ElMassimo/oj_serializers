# frozen_string_literal: true

require 'spec_helper'

require 'oj_serializers/sugar'
require 'support/controllers/albums_controller'

RSpec.describe AlbumsController, type: :controller do
  it 'should work as expected' do
    get :index
    get :show, params: { id: 'example' }
    binding.pry
  end
end
