# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'AlbumSerializer', :benchmark do
  context 'albums' do
    it 'serializing a model' do
      album = Album.abraxas
      expect(AlbumSerializer.one(album, special: true).to_json).to eq LegacyAlbumSerializer.new(album, special: true).to_json
      expect(AlbumSerializer.one(album, special: true).to_json).to eq AlbumBlueprint.render(album, special: true)
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.one_as_json(album)
        end
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.one_as_hash(album)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(album)
        end
        x.report('active_model_serializers') do
          Oj.dump LegacyAlbumSerializer.new(album)
        end
        x.compare!
      end
    end

    it 'serializing a collection' do
      albums = 100.times.map { Album.abraxas }
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many_as_json(albums)
        end
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.many_as_hash(albums)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) })
        end
        x.compare!
      end
    end

    it 'serializing a large collection' do
      albums = 1000.times.map { Album.abraxas }
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many_as_json(albums)
        end
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.many_as_hash(albums)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) })
        end
        x.compare!
      end
    end
  end
end
