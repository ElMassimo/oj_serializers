# frozen_string_literal: true

require 'benchmark_helper'
require 'support/serializers/album_serializer'
require 'support/serializers/legacy_serializers'
require 'support/serializers/blueprints'
require 'support/models/album'

RSpec.describe 'Memory Usage' do
  let!(:album) { Album.abraxas.tap(&:attributes) }
  let!(:albums) do
    1000.times.map { Album.abraxas.tap(&:attributes) }
  end

  def format_number(number)
    whole, decimal = number.to_s.split('.')
    if whole.to_i < -999 || whole.to_i > 999
      whole.reverse!.gsub!(/(\d{3})(?=\d)/, '\\1,').reverse!
    end
    [whole, decimal].compact.join('.')
  end

  it 'should require less memory when serializing an object' do
    AlbumSerializer.send(:instance)

    oj_report = MemoryProfiler.report { AlbumSerializer.one(album).to_json }
    bytes_allocated_by_oj = oj_report.allocated_memory_by_class.sum { |data| data[:count] }

    ams_report = MemoryProfiler.report { LegacyAlbumSerializer.new(album).to_json }
    bytes_allocated_by_ams = ams_report.allocated_memory_by_class.sum { |data| data[:count] }

    blueprint_report = MemoryProfiler.report { AlbumBlueprint.render(album) }
    bytes_allocated_by_blueprint = blueprint_report.allocated_memory_by_class.sum { |data| data[:count] }

    puts "Bytes allocated by ams: #{format_number bytes_allocated_by_ams}"
    puts "Bytes allocated by blueprinter: #{format_number bytes_allocated_by_blueprint}"
    puts "Bytes allocated by oj_serializers: #{format_number bytes_allocated_by_oj}"

    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_ams
    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_blueprint
    expect(bytes_allocated_by_oj / bytes_allocated_by_ams.to_f).to be < 0.25
  end

  it 'should require less memory when serializing a collection' do
    AlbumSerializer.send(:instance)

    oj_report = MemoryProfiler.report { Oj.dump AlbumSerializer.many(albums) }
    bytes_allocated_by_oj = oj_report.allocated_memory_by_class.sum { |data| data[:count] }

    ams_report = MemoryProfiler.report { Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) }) }
    bytes_allocated_by_ams = ams_report.allocated_memory_by_class.sum { |data| data[:count] }

    blueprint_report = MemoryProfiler.report { AlbumBlueprint.render(albums) }
    bytes_allocated_by_blueprint = blueprint_report.allocated_memory_by_class.sum { |data| data[:count] }

    puts "Bytes allocated by ams: #{format_number bytes_allocated_by_ams}"
    puts "Bytes allocated by blueprinter: #{format_number bytes_allocated_by_blueprint}"
    puts "Bytes allocated by oj_serializers: #{format_number bytes_allocated_by_oj}"

    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_ams
    expect(bytes_allocated_by_oj).to be < bytes_allocated_by_blueprint
    expect(bytes_allocated_by_oj / bytes_allocated_by_ams.to_f).to be < 0.25
  end
end
