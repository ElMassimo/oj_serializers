# frozen_string_literal: true

require 'spec_helper'
require 'support/models/album'
require 'support/serializers/invalid_album_serializer'

class StatefulSerializer < Oj::Serializer
  hash_attributes 'genre'

  attribute
  def name
    @name ||= @object.name
  end
end

class MissingAttributeSerializer < Oj::Serializer
  mongo_attributes(:name2)
end

RSpec.describe 'Development Mode', type: :serializer do
  let(:album) { Album.abraxas }

  before do
    expect(Oj::Serializer::DEV_MODE).to eq true
  end

  it 'should fail early when memoization is used incorrectly' do
    expect { StatefulSerializer.many([album, album]) }
      .to raise_error(ArgumentError, 'Serializer instances are reused so they must be stateless. Use `memo.fetch` for memoization purposes instead. Bad keys: name in StatefulSerializer')
  end

  it 'should fail early when `attributes` is used instead of `serializer_attributes`' do
    expect { InvalidAlbumSerializer.one(album) }
      .to raise_error(NoMethodError, /Perhaps you meant to call "release" in InvalidAlbumSerializer instead?/)
  end

  xit 'should fail early when there is a typo or missing field in Mongoid' do
    expect { MissingAttributeSerializer.one_if(album) }
      .to raise_error(ActiveModel::MissingAttributeError, /Missing attribute: 'name2'/)
  end
end
