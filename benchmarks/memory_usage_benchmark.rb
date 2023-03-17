# frozen_string_literal: true

require 'benchmark_helper'
require 'support/serializers/album_serializer'
require 'support/serializers/legacy_serializers'
require 'support/models/album'

RSpec.describe 'Memory Usage' do
  let!(:album) { Album.abraxas.tap(&:attributes) }
  let!(:albums) do
    1000.times.map { Album.abraxas.tap(&:attributes) }
  end

  before do
    AlbumSerializer.send(:instance)
  end

  it 'should require less memory when serializing an object' do
    oj_report = MemoryProfiler.report { AlbumSerializer.one(album).to_json }
    bytes_allocated_by_oj = oj_report.allocated_memory_by_class.sum { |data| data[:count] }

    ams_report = MemoryProfiler.report { LegacyAlbumSerializer.new(album).to_json }
    bytes_allocated_by_ams = ams_report.allocated_memory_by_class.sum { |data| data[:count] }

    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_ams
    expect(bytes_allocated_by_oj / bytes_allocated_by_ams.to_f).to be < 0.35
  end

  it 'should require less memory when serializing a collection' do
    oj_report = MemoryProfiler.report { Oj.dump AlbumSerializer.many(albums) }
    bytes_allocated_by_oj = oj_report.allocated_memory_by_class.sum { |data| data[:count] }

    ams_report = MemoryProfiler.report { Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) }) }
    bytes_allocated_by_ams = ams_report.allocated_memory_by_class.sum { |data| data[:count] }

    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_ams
    expect(bytes_allocated_by_oj / bytes_allocated_by_ams.to_f).to be < 0.33
  end
end
