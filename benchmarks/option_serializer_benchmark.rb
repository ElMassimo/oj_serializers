# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'OptionSerializer', :benchmark do
  context 'albums' do
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing models' do
      some = albums.take(1)
      expect(Oj.dump(OptionSerializer::Oj.many(some))).to eq OptionSerializer::Blueprinter.render(some)
      expect(Oj.dump(OptionSerializer::Oj.many(some))).to eq(Oj.dump(some.map { |album| OptionSerializer::AMS.new(album) }))

      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers') do
          Oj.dump OptionSerializer::Oj.many(albums)
        end
        x.report('oj_serializers (hash)') do
          Oj.dump OptionSerializer::Oj.many_as_hash(albums)
        end
        x.report('map_models') do
          Oj.dump OptionSerializer.map_models(albums)
        end
        x.report('write_models') do
          Oj.dump OptionSerializer.write_models(albums)
        end
        x.report('active_model_serializers') do
          Oj.dump(albums.map { |album| OptionSerializer::AMS.new(album) })
        end
        x.report('blueprinter') do
          OptionSerializer::Blueprinter.render(albums)
        end
        x.compare!
      end
    end
  end
end
