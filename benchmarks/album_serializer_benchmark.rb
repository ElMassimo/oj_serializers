# frozen_string_literal: true

require 'benchmark_helper'

require 'rails'
require 'active_support/json'
require 'oj_serializers/compat'
require 'support/serializers/active_model_serializer'
require 'support/serializers/album_serializer'
require 'support/serializers/legacy_serializers'
require 'support/models/album'

RSpec.describe AlbumSerializer, category: :benchmark do
  context 'albums' do
    let(:album) { Album.abraxas }
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing a model' do
      expect(AlbumSerializer.one(album, special: true).to_json).to eq LegacyAlbumSerializer.new(album, special: true).to_json
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.one(album)
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
        x.report('oj_serializers') do
          Oj.dump AlbumSerializer.many(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump albums.map { |album| LegacyAlbumSerializer.new(album) }
        end
        x.compare!
      end
    end
  end
end
