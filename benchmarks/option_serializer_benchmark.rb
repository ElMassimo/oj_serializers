# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'OptionSerializer', :benchmark do
  context 'albums' do
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing models' do
      some = albums.take(1)
      expect(JSON.generate(OptionSerializer::Oj.many(some))).to eq OptionSerializer::Blueprinter.render(some)
      expect(JSON.generate(OptionSerializer::Oj.many(some))).to eq(JSON.generate(some.map { |album| OptionSerializer::AMS.new(album) }))

      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          JSON.generate(OptionSerializer::Oj.many(albums))
        end
        x.report('map_models') do
          JSON.generate(OptionSerializer.map_models(albums))
        end
        x.report('alba') do
          OptionSerializer::Alba.new(albums).serialize
        end
        x.report('panko') do
          Panko::ArraySerializer.new(albums, each_serializer: OptionSerializer::Panko).to_json
        end
        x.report('active_model_serializers') do
          JSON.generate(albums.map { |album| OptionSerializer::AMS.new(album) })
        end
        x.report('blueprinter') do
          OptionSerializer::Blueprinter.render(albums)
        end
        x.compare!
      end
    end
  end
end
