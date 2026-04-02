# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'Memory Usage', :benchmark do
  let(:album) { Album.abraxas.tap(&:attributes) }
  let(:albums) do
    1000.times.map { Album.abraxas.tap(&:attributes) }
  end

  before do
    AlbumSerializer.one_as_hash(album)
    LegacyAlbumSerializer.new(album).to_json
    AlbumBlueprint.render(album)
    AlbumAlba.new(album).serialize
    AlbumPanko.new.serialize_to_json(album)
  end

  def allocated_by(entry)
    entry.measurement.memory.allocated.to_float
  end

  it 'should require less memory when serializing an object' do
    album
    report = Benchmark.memory do |x|
      x.report('json_serializers') { JSON.generate(AlbumSerializer.one(album)) }
      x.report('ams') { JSON.generate(LegacyAlbumSerializer.new(album).as_json) }
      x.report('alba') { AlbumAlba.new(album).serialize }
      x.report('panko') { AlbumPanko.new.serialize_to_json(album) }
      x.report('blueprinter') { AlbumBlueprint.render(album) }
      x.compare!
    end
  end

  it 'should require less memory when serializing a collection' do
    albums
    report = Benchmark.memory do |x|
      x.report('json_serializers') { JSON.generate(AlbumSerializer.many(albums)) }
      x.report('ams') { JSON.generate(albums.map { |album| LegacyAlbumSerializer.new(album).as_json }) }
      x.report('alba') { AlbumAlba.new(albums).serialize }
      x.report('panko') { Panko::ArraySerializer.new(albums, each_serializer: AlbumPanko).to_json }
      x.report('blueprinter') { AlbumBlueprint.render(albums) }
      x.compare!
    end
  end
end
