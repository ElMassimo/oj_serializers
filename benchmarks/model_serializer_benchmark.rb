# frozen_string_literal: true

require 'benchmark_helper'

require 'rails'
require 'active_support/json'
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
          Oj.dump ModelSerializer.many(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump albums.map { |album| ActiveModelSerializer.new(album) }
        end
        x.compare!
      end
    end
  end
end
