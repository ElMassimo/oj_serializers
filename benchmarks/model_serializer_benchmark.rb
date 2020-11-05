# frozen_string_literal: true

require 'benchmark_helper'

require 'oj_serializers/compat'
require 'support/serializers/active_model_serializer'
require 'support/serializers/model_serializer'
require 'support/models/album'

RSpec.describe ModelSerializer, category: :benchmark do
  context 'albums' do
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing models' do
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          ModelSerializer.many(albums).to_json
        end
        x.report('active_model_serializers') do
          albums.map { |album| ActiveModelSerializer.new(album) }.to_json
        end
        x.report('oj_serializers (encoder)') do
          OjSerializers::JsonStringEncoder.encode_to_json(albums, each_serializer: ModelSerializer)
        end
        x.report('active_model_serializers (encoder)') do
          OjSerializers::JsonStringEncoder.encode_to_json(albums, each_serializer: ActiveModelSerializer)
        end
        x.compare!
      end
    end
  end
end
