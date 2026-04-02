# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'ModelSerializer', :benchmark do
  context 'albums' do
    let!(:albums) do
      100.times.map { Album.abraxas }
    end

    it 'serializing models' do
      benchmark_section('ModelSerializer: 100 albums') do |x|
        x.report('json_serializers') do
          JSON.generate(ModelSerializer.many(albums))
        end
        x.report('panko') do
          Panko::ArraySerializer.new(albums, each_serializer: ModelPanko).to_json
        end
        x.report('alba') do
          ModelAlba.new(albums).serialize
        end
        x.report('blueprinter') do
          ModelBlueprint.render(albums)
        end
        x.report('active_model_serializers') do
          JSON.generate(albums.map { |album| ActiveModelSerializer.new(album).as_json })
        end
        x.compare!
      end
    end
  end
end
