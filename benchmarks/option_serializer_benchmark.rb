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
          Oj.dump OptionSerializer.write_models(albums)
        end
        x.report('oj_serializers') do
          Oj.dump OptionSerializer::Oj.many(albums)
        end
        x.report('map') do
          Oj.dump OptionSerializer.map_models(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump albums.map { |album| OptionSerializer::AMS.new(album) }
        end
        x.compare!
      end
    end
  end
end
