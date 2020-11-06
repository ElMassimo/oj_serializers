# frozen_string_literal: true

require 'benchmark_helper'
require 'support/models/album'

RSpec.describe 'Document Accessors', category: :benchmark do
  let(:album) { Album.abraxas }

  it 'getters performance' do
    Benchmark.ips do |x|
      x.config(time: 2, warmup: 1)
      x.report('album.name') { album.name }
      x.report("album['name']") { album['name'] }
      x.report("album.attributes['name']") { album.attributes['name'] }
      x.report("album.read_attribute('name')") { album.read_attribute('name') }
      x.compare!
    end
  end
end
