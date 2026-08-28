# frozen_string_literal: true

require 'spec_helper'
require 'support/models/song'

# Uses `as`: key on the left is the source, `as` is the output name.
class AsSongSerializer < Oj::Serializer
  attributes(
    name: { as: :label, type: :string },
    composer: { as: :value, type: :unknown },
  )
end

# Uses `from`: key on the left is the output name, `from` is the source.
# This should be equivalent to the serializer above.
class FromSongSerializer < Oj::Serializer
  attributes(
    label: { from: :name, type: :string },
    value: { from: :composer, type: :unknown },
  )
end

RSpec.describe 'from (inverse of as)' do
  let(:song) { Song.new(name: 'Oye Como Va', composer: 'Tito Puente') }

  it 'renames the output key using the definition key' do
    expect_parsed_json(FromSongSerializer.one(song)).to eq(
      label: 'Oye Como Va',
      value: 'Tito Puente',
    )
  end

  it 'produces the same output as the equivalent `as` definition' do
    expect(FromSongSerializer.one(song)).to eq(AsSongSerializer.one(song))
  end

  it 'stores the same underlying attribute metadata as `as`' do
    expect(FromSongSerializer._attributes).to eq(AsSongSerializer._attributes)
  end
end
