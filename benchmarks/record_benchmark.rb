# frozen_string_literal: true

require 'benchmark_helper'
require 'support/models/sql'

RSpec.describe 'Record Accessors', :benchmark do
  let(:player) { Game.example.players.first }

  it 'getters performance' do
    benchmark_section('Record Accessors', time: 2, warmup: 1) do |x|
      x.report('player.first_name') { player.first_name }
      x.report('player.send(:first_name)') { player.send(:first_name) }
      x.report("player['first_name']") { player['first_name'] }
      x.report("player.attributes['first_name']") { player.attributes['first_name'] }
      x.report("player.read_attribute('first_name')") { player.read_attribute('first_name') }
      x.report("player._read_attribute('first_name')") { player._read_attribute('first_name') }
      x.compare!
    end
  end
end
