# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OjSerializers::Memo do
  let(:memo) { described_class.new }

  it 'should memoize the values if they were not available' do
    sum = 1
    expect(memo.fetch(:sum) { sum }).to eq 1
    sum += 1
    expect(memo.fetch(:sum) { sum }).to eq 1

    memo.clear
    expect(memo.fetch(:sum) { sum }).to eq 2
    sum += 1
    expect(memo.fetch(:sum) { sum }).to eq 2
  end
end
