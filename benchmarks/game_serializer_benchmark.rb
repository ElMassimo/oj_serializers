# frozen_string_literal: true

require 'benchmark_helper'
require 'support/models/sql'

class PlayerPanko < Panko::Serializer
  attributes :id, :first_name, :last_name, :full_name

  def id
    object.id if object.persisted?
  end

  def full_name
    object.full_name
  end
end

# NOTE: This example is quite contrived. Finding good test cases is as hard as
# finding good names.
class ScoresPanko < Panko::Serializer
  attributes :high_score, :score
end

class GamePanko < Panko::Serializer
  attributes :id, :name

  has_one :scores, serializer: ScoresPanko

  has_one :best_player, serializer: PlayerPanko
  has_many :players, serializer: PlayerPanko

  def id
    object.id if object.persisted?
  end
end

Game.prepend Module.new {
  def scores
    self
  end
}

RSpec.describe 'GameSerializer', :benchmark do
  context 'albums' do
    it 'serializing a model' do
      game = Game.example

      Benchmark.ips do |x|
        x.config(time: 5, warmup: 2)
        x.report('oj_serializers as_hash') do
          Oj.dump GameSerializer.one_as_hash(game)
        end
        x.report('oj_serializers') do
          Oj.dump GameSerializer.one_as_json(game)
        end
        x.report('panko') do
          GamePanko.new.serialize_to_json(game)
        end
        x.compare!
      end
    end
  end
end
