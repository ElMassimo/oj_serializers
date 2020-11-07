# frozen_string_literal: true

require 'active_record'
require 'sqlite3'

# Change the following to reflect your database settings
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

# Don't show migration output when constructing fake db
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :games, force: true do |t|
    t.string :name
    t.integer :high_score, default: 500
    t.integer :score, default: 0

    t.references :players
    t.references :best_player
  end

  create_table :players, force: true do |t|
    t.string :first_name
    t.string :last_name
    t.references :games

    t.timestamps(null: false)
  end
end

class Game < ActiveRecord::Base
  belongs_to :best_player

  has_many :players

  def self.example
    best_player = Player.new(first_name: 'Alexey', last_name: 'Pajitnov')
    new(
      name: 'Tetris',
      high_score: 1500,
      score: 3165,
      best_player: best_player,
      players: [
        best_player,
        Player.new(first_name: 'Vadim', last_name: 'Gerasimov'),
      ],
    )
  end
end

class Player < ActiveRecord::Base
  has_many :games

  def full_name
    "#{first_name} #{last_name}"
  end
end
