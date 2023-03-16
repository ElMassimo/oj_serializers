# frozen_string_literal: true

require 'benchmark_helper'

require 'rails'
require 'active_support/json'
require 'oj_serializers/compat'
require 'support/serializers/active_model_serializer'
require 'support/serializers/album_serializer'
require 'support/serializers/legacy_serializers'
require 'support/serializers/blueprints'
require 'support/models/album'

RSpec.describe AlbumSerializer, category: :benchmark do
  context 'albums' do
    let(:album) { Album.abraxas }
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing a model' do
      expect(AlbumSerializer.one(album, special: true).to_json).to eq LegacyAlbumSerializer.new(album, special: true).to_json
      expect(AlbumSerializer.one(album, special: true).to_json).to eq AlbumBlueprint.render(album, special: true)
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.one(album)
        end
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.one_as_hash(album)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(album)
        end
        x.report('blueprinter as_hash') do
          Oj.dump AlbumBlueprint.render_as_hash(album)
        end
        x.report('active_model_serializers') do
          Oj.dump LegacyAlbumSerializer.new(album)
        end
        x.compare!
      end
    end

    it 'serializing a collection' do
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers no dump') do
          AlbumSerializer.many(albums)
        end
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many(albums)
        end
        x.report('oj_serializers to_s') do
          AlbumSerializer.many(albums).to_s
        end
        x.report('oj_serializers as_hash') do
          Oj.dump AlbumSerializer.many_as_hash(albums)
        end
        x.report('blueprinter') do
          AlbumBlueprint.render(albums)
        end
        x.report('blueprinter as_hash') do
          Oj.dump AlbumBlueprint.render_as_hash(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) })
        end
        x.compare!
      end
    end
  end
end
