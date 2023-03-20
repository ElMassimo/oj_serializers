# frozen_string_literal: true

require 'benchmark_helper'

RSpec.describe 'Memory Usage', :benchmark do
  let(:album) { Album.abraxas.tap(&:attributes) }
  let(:albums) do
    1000.times.map { Album.abraxas.tap(&:attributes) }
  end

  before do
    AlbumSerializer.one_as_hash(album)
    LegacyAlbumSerializer.new(album).to_json
    AlbumBlueprint.render(album)
  end

  def allocated_by(entry)
    entry.measurement.memory.allocated.to_f
  end

  it 'should require less memory when serializing an object' do
    album
    report = Benchmark.memory do |x|
      x.report('oj') { Oj.dump AlbumSerializer.one_as_json(album) }
      x.report('oj_hash') { Oj.dump AlbumSerializer.one_as_hash(album) }
      x.report('ams') { Oj.dump LegacyAlbumSerializer.new(album) }
      x.report('blueprinter') { AlbumBlueprint.render(album) }
      x.compare!
    end
    entries = report.comparison.entries
    oj1, oj2, *rest = entries.map(&:label)
    expect([oj1, oj2]).to contain_exactly(*%w[oj_hash oj])
    expect(rest).to eq %w[blueprinter ams]
    expect(allocated_by(entries.first) / allocated_by(entries.last)).to be < 0.365
  end

  it 'should require less memory when serializing a collection' do
    albums
    report = Benchmark.memory do |x|
      x.report('oj') { Oj.dump AlbumSerializer.many_as_json(albums) }
      x.report('oj_hash') { Oj.dump AlbumSerializer.many_as_hash(albums) }
      x.report('ams') { Oj.dump(albums.map { |album| LegacyAlbumSerializer.new(album) }) }
      x.report('blueprinter') { AlbumBlueprint.render(albums) }
      x.compare!
    end
    entries = report.comparison.entries
    expect(entries.map(&:label)).to eq %w[oj oj_hash blueprinter ams]
    expect(allocated_by(entries.first) / allocated_by(entries.last)).to be < 0.33
  end
end
