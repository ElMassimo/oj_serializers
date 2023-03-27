# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'AlbumSerializer', :benchmark do
  context 'albums' do
    before(:all) do
      album = Album.abraxas
      output = AlbumSerializer.one(album, special: true).to_json
      expect(output).to eq LegacyAlbumSerializer.new(album, special: true).to_json
      expect(output).to eq AlbumBlueprint.render(album, special: true)
      expect(JSON.parse(output)).to eq JSON.parse AlbumPanko.new(context: { special: true }).serialize_to_json(album)
      expect(JSON.parse(output)).to eq JSON.parse AlbumAlba.new(album, params: { special: true }).serialize
    end

    it 'serializing a model' do
      album = Album.abraxas
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.one_as_hash(album)
        end
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.one_as_json(album)
        end
        x.report('panko') do
          AlbumPanko.new.serialize_to_json(album)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(album)
        end
        x.report('active_model_serializers') do
          Oj.dump LegacyAlbumSerializer.new(album)
        end
        x.report('alba') do
          AlbumAlba.new(album).serialize
        end
        x.compare!
      end
    end

    it 'serializing a collection' do
      albums = 100.times.map { Album.abraxas }
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.many_as_hash(albums)
        end
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many_as_json(albums)
        end
        x.report('panko') do
          Panko::ArraySerializer.new(albums, each_serializer: AlbumPanko).to_json
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) })
        end
        x.report('alba') do
          AlbumAlba.new(albums).serialize
        end
        x.compare!
      end
    end

    it 'serializing a large collection' do
      albums = 1000.times.map { Album.abraxas }
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.many_as_hash(albums)
        end
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many_as_json(albums)
        end
        x.report('panko') do
          Panko::ArraySerializer.new(albums, each_serializer: AlbumPanko).to_json
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) })
        end
        x.report('alba') do
          AlbumAlba.new(albums).serialize
        end
        x.compare!
      end
    end
  end
end
