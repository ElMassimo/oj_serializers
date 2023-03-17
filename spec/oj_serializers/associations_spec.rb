# frozen_string_literal: true

require 'spec_helper'
require 'support/models/sql'

RSpec.describe 'Associations', type: :serializer do
  let!(:game) { Game.example }
  let!(:games) { [game] * 2 }

  it 'should render has_one, has_many, and flat_one' do
    attrs = {
      name: 'Tetris',
      high_score: 1500,
      score: 3165,
      best_player: { first_name: 'Alexey', last_name: 'Pajitnov', full_name: 'Alexey Pajitnov' },
      players: [
        { first_name: 'Alexey', last_name: 'Pajitnov', full_name: 'Alexey Pajitnov' },
        { first_name: 'Vadim', last_name: 'Gerasimov', full_name: 'Vadim Gerasimov' },
      ],
    }
    puts GameSerializer.send(:render_as_hash_body)
    expect_parsed_json(GameSerializer.one(game)).to eq attrs
    expect_parsed_json(GameSerializer.many(games)).to eq [attrs, attrs]
  end
end
