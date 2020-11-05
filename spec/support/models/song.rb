# frozen_string_literal: true

require 'mongoid'

class Song
  include Mongoid::Document

  field :name, type: String
  field :composer, type: String
  field :track, type: Integer

  embedded_in :album
end
