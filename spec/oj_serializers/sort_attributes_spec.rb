# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/album_serializer'
require 'support/serializers/large_album_serializer'

class SortedAlbumSerializer < AlbumSerializer
  sort_attributes_by :name
end

class UnsortedAlbumSerializer < AlbumSerializer
  sort_attributes_by :definition
  transform_keys :none

  identifier :release_date
end

class UnsortedLargeAlbumSerializer < LargeAlbumSerializer
  sort_attributes_by :definition
  transform_keys :none

  identifier :release_date
end

RSpec.describe 'sort_attributes_by' do
  let(:album) { Album.abraxas }

  before do
    allow(album).to receive(:new_record?).and_return(false)
  end

  it 'should not sort attributes when not specified' do
    expect_parsed_json(AlbumSerializer.one(album)).to have_attributes(
      keys: %i[id name genres release songs],
    )
  end

  it 'should sort attributes by name' do
    expect_parsed_json(SortedAlbumSerializer.one(album)).to have_attributes(
      keys: %i[id genres name release songs],
    )
  end

  it 'should sort attributes by definition order' do
    expect_parsed_json(UnsortedAlbumSerializer.one(album)).to have_attributes(
      keys: %i[id release_date name genres release songs],
    )
  end

  it 'should sort large attributes list by definition order' do
    expect_parsed_json(UnsortedLargeAlbumSerializer.one(album)).to have_attributes(
      keys: %i[id release_date name genres release songs year day month band label producer]
    )
  end
end
