# frozen_string_literal: true

require 'spec_helper'

require 'oj_serializers/json_string_encoder'

class CustomValue
  def as_json(*)
    'custom'
  end
end

RSpec.describe OjSerializers::JsonStringEncoder, type: :serializer do
  def expect_encoded_json(object, options = {})
    expect(OjSerializers::JsonStringEncoder.encode_to_json(object, **options).tr("\n", ''))
  end

  def expect_incorrect_usage(object, options = {})
    expect { OjSerializers::JsonStringEncoder.encode_to_json(object, **options) }
  end

  let(:hash) { { a: 1, b: '2', c: nil, d: false, e: BSON::ObjectId.new, f: CustomValue.new } }

  context 'primitive values' do
    it 'should not encode strings' do
      json_string = hash.to_json
      expect_encoded_json(json_string).to eq json_string
      expect_encoded_json(json_string, root: :string).to eq "{\"string\":#{json_string}}"
      expect_encoded_json(hash, root: :string).to eq "{\"string\":#{json_string}}"
    end

    it 'should encode hashes normally' do
      expect_encoded_json(hash).to eq(hash.to_json)
      expect_encoded_json(hash, root: :object).to eq({ object: hash }.to_json)
    end

    it 'should encode arrays normally' do
      expect_encoded_json([hash]).to eq([hash].to_json)
      expect_encoded_json([hash, hash], root: :arrays).to eq({ arrays: [hash, hash] }.to_json)
    end

    it 'should not double encode JsonValue' do
      json_string = hash.to_json
      complex = [{ complex: OjSerializers::JsonValue.new(json_string) }]
      expect_encoded_json(complex).to eq([{ complex: hash }].to_json)
      expect_encoded_json(complex, root: :mixed).to eq({ mixed: [{ complex: hash }] }.to_json)

      json_strings = [json_string, json_string]
      complex_array = [{ complex_array: OjSerializers::JsonValue.array(json_strings) }]
      expect_encoded_json(complex_array).to eq([{ complex_array: [hash, hash] }].to_json)
      expect_encoded_json(complex_array, root: :mixed).to eq({ mixed: [{ complex_array: [hash, hash] }] }.to_json)

      expect(complex.as_json.to_json).to eq([{ complex: hash }].to_json)
      expect(OjSerializers::JsonValue.new(json_string).to_s).to eq json_string
    end
  end

  context 'models and old serializers' do
    before(:all) do
      require 'support/models/album'
      require 'support/serializers/album_serializer'
    end
    let(:album) { Album.abraxas }
    let(:album_hash) do
      {
        name: 'Abraxas',
        genres: [
          'Pyschodelic Rock',
          'Blues Rock',
          'Jazz Fusion',
          'Latin Rock',
        ],
        release: 'September 23, 1970',
        songs: [
          {
            track: 1,
            name: 'Sing Winds, Crying Beasts',
            composers: [
              'Michael Carabello',
            ],
          },
          {
            track: 2,
            name: 'Black Magic Woman / Gypsy Queen',
            composers: [
              'Peter Green',
              'Gábor Szabó',
            ],
          },
          {
            track: 3,
            name: 'Oye como va',
            composers: [
              'Tito Puente',
            ],
          },
          {
            track: 4,
            name: 'Incident at Neshabur',
            composers: [
              'Alberto Gianquinto',
              'Carlos Santana',
            ],
          },
          {
            track: 5,
            name: 'Se acabó',
            composers: [
              'José Areas',
            ],
          },
          {
            track: 6,
            name: "Mother's Daughter",
            composers: [
              'Gregg Rolie',
            ],
          },
          {
            track: 7,
            name: 'Samba pa ti',
            composers: [
              'Santana',
            ],
          },
          {
            track: 8,
            name: "Hope You're Feeling Better",
            composers: [
              'Rolie',
            ],
          },
          {
            track: 9,
            name: 'El Nicoya',
            composers: [
              'Areas',
            ],
          },
        ],
      }
    end

    it 'should encode using old serializers if provided' do
      require 'support/serializers/active_model_serializer'
      attrs = { id: album.id, name: album.name }
      expect_encoded_json(album: ActiveModelSerializer.new(album)).to eq({ album: attrs }.to_json)
      expect_encoded_json(ActiveModelSerializer.new(album), root: :album).to eq({ album: attrs }.to_json)
      expect_encoded_json(album, serializer: ActiveModelSerializer, root: :album).to eq({ album: attrs }.to_json)
      expect_encoded_json([album], each_serializer: ActiveModelSerializer, root: :albums).to eq({ albums: [attrs] }.to_json)
    end

    it 'should use the each_serializer option on list of objects' do
      expect_encoded_json([album], each_serializer: AlbumSerializer).to eq([album_hash].to_json)
      expect_encoded_json([album], root: :albums, each_serializer: AlbumSerializer).to eq({ albums: [album_hash] }.to_json)
      expect_encoded_json(albums: [AlbumSerializer.one(album)]).to eq({ albums: [album_hash] }.to_json)
      expect_encoded_json(albums: AlbumSerializer.many([album])).to eq({ albums: [album_hash] }.to_json)
    end

    it 'should use the serializer option on single objects' do
      expect_encoded_json(album, serializer: AlbumSerializer).to eq(album_hash.to_json)
      expect_encoded_json(album, root: :album, serializer: AlbumSerializer).to eq({ album: album_hash }.to_json)
      expect_encoded_json(album: AlbumSerializer.one(album)).to eq({ album: album_hash }.to_json)
    end

    it 'should fail early when used incorrectly' do
      expect_incorrect_usage([album], serializer: AlbumSerializer).to raise_error(ArgumentError, 'You must use `each_serializer` when serializing collections')
      expect_incorrect_usage(album, each_serializer: AlbumSerializer).to raise_error(ArgumentError, 'You must use `serializer` when serializing a single object')
    end
  end
end
