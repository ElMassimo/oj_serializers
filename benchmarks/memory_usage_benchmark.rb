# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'Memory Usage', :benchmark do
  let!(:album) { Album.abraxas.tap(&:attributes) }
  let!(:albums) do
    1000.times.map { Album.abraxas.tap(&:attributes) }
  end

  before do
    AlbumSerializer.send(:instance)
  end

  def format_number(number)
    whole, decimal = number.to_s.split('.')
    if whole.to_i < -999 || whole.to_i > 999
      whole.reverse!.gsub!(/(\d{3})(?=\d)/, '\\1,').reverse!
    end
    [whole, decimal].compact.join('.')
  end

  def report_allocated_bytes
    MemoryProfiler.report { yield }
      .allocated_memory_by_class.sum { |data| data[:count] }
  end

  it 'should require less memory when serializing an object' do
    AlbumSerializer.send(:instance)

    oj_bytes = report_allocated_bytes { Oj.dump AlbumSerializer.one_as_json(album) }
    oj_hash_bytes = report_allocated_bytes { Oj.dump AlbumSerializer.one_as_hash(album) }
    ams_bytes = report_allocated_bytes { Oj.dump LegacyAlbumSerializer.new(album) }
    blueprint_bytes = report_allocated_bytes { AlbumBlueprint.render(album) }

    puts "Bytes allocated by ams: #{format_number ams_bytes}"
    puts "Bytes allocated by blueprinter: #{format_number blueprint_bytes}"
    puts "Bytes allocated by oj_serializers: #{format_number oj_bytes}"
    puts "Bytes allocated by oj_serializers (hash): #{format_number oj_hash_bytes}"

    expect(oj_hash_bytes).to be < ams_bytes
    expect(oj_hash_bytes).to be < blueprint_bytes
    expect(oj_bytes).to be < ams_bytes
    expect(oj_bytes).to be < blueprint_bytes
    expect(oj_bytes / ams_bytes.to_f).to be < 0.365
  end

  it 'should require less memory when serializing a collection' do
    AlbumSerializer.send(:instance)

    oj_bytes = report_allocated_bytes { Oj.dump AlbumSerializer.many_as_json(albums) }
    oj_hash_bytes = report_allocated_bytes { Oj.dump AlbumSerializer.many_as_hash(albums) }
    ams_bytes = report_allocated_bytes { Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) }) }
    blueprint_bytes = report_allocated_bytes { AlbumBlueprint.render(albums) }

    puts "Bytes allocated by ams: #{format_number ams_bytes}"
    puts "Bytes allocated by blueprinter: #{format_number blueprint_bytes}"
    puts "Bytes allocated by oj_serializers: #{format_number oj_bytes}"
    puts "Bytes allocated by oj_serializers (hash): #{format_number oj_hash_bytes}"

    expect(oj_hash_bytes).to be < ams_bytes
    expect(oj_hash_bytes).to be < blueprint_bytes
    expect(oj_bytes).to be < ams_bytes
    expect(oj_bytes).to be < blueprint_bytes
    expect(oj_bytes / ams_bytes.to_f).to be < 0.33
  end
end
