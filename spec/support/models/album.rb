# frozen_string_literal: true

require_relative 'song'

class Album
  include Mongoid::Document

  field :name, type: String
  field :genres, type: Array
  field :release_date, type: Date

  embeds_many :songs

  def released?
    release_date?
  end

  def self.abraxas
    new(
      name: 'Abraxas',
      genres: ['Pyschodelic Rock', 'Blues Rock', 'Jazz Fusion', 'Latin Rock'],
      release_date: Date.new(1970, 9, 23),
      songs: [
        Song.new(track: 1, name: 'Sing Winds, Crying Beasts', composer: 'Michael Carabello'),
        Song.new(track: 2, name: 'Black Magic Woman / Gypsy Queen', composer: 'Peter Green, Gábor Szabó'),
        Song.new(track: 3, name: 'Oye como va', composer: 'Tito Puente'),
        Song.new(track: 4, name: 'Incident at Neshabur', composer: 'Alberto Gianquinto, Carlos Santana'),
        Song.new(track: 5, name: 'Se acabó', composer: 'José Areas'),
        Song.new(track: 6, name: "Mother's Daughter", composer: 'Gregg Rolie'),
        Song.new(track: 7, name: 'Samba pa ti', composer: 'Santana'),
        Song.new(track: 8, name: "Hope You're Feeling Better", composer: 'Rolie'),
        Song.new(track: 9, name: 'El Nicoya', composer: 'Areas'),
      ],
    )
  end
end
