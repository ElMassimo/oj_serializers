# frozen_string_literal: true

require 'benchmark_helper'

require 'rails'
require 'active_support/json'
require 'oj_serializers/compat'
require 'support/serializers/option_serializer'
require 'support/models/album'

RSpec.describe OptionSerializer, category: :benchmark do
  context 'albums' do
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing models' do
      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('string_writer') do
          OptionSerializer.write_models(albums).to_json
        end
        x.report('oj_serializers') do
          OptionSerializer::Oj.many(albums).to_json
        end
        x.report('map') do
          OptionSerializer.map_models(albums).to_json
        end
        x.report('active_model_serializers') do
          albums.map { |album| OptionSerializer::AMS.new(album) }.to_json
        end
        x.report('oj_serializers (encoder)') do
          OjSerializers::JsonStringEncoder.encode_to_json(albums, each_serializer: OptionSerializer::Oj)
        end
        x.report('active_model_serializers (encoder)') do
          OjSerializers::JsonStringEncoder.encode_to_json(albums, each_serializer: OptionSerializer::AMS)
        end
        x.compare!
      end
    end
  end
end
