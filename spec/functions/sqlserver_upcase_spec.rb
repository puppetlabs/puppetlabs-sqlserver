# frozen_string_literal: true

require 'spec_helper'

describe 'the sqlserver_upcase function' do
  it 'exists' do
    expect(Puppet::Parser::Functions.function('sqlserver_upcase')).to eq('function_sqlserver_upcase')
  end

  it 'upcases a string' do
    result = scope.function_sqlserver_upcase(['abc'])
    expect(result).to(eq('ABC'))
  end

  it 'does nothing if a string is already upcase' do
    result = scope.function_sqlserver_upcase(['ABC'])
    expect(result).to(eq('ABC'))
  end

  it 'accepts objects which extend String' do
    class AlsoString < String
    end

    value = AlsoString.new('abc')
    result = scope.function_sqlserver_upcase([value])
    result.should(eq('ABC'))
  end

  it 'accepts hashes and return uppercase' do
    expect(
      scope.function_sqlserver_upcase([{ 'test' => ['this', 'that', 'and', 'other', 'thing'] }]),
    ).to eq('TEST' => ['THIS', 'THAT', 'AND', 'OTHER', 'THING'])
  end

  if :test.respond_to?(:upcase)
    it 'accepts hashes of symbols' do
      expect(
        scope.function_sqlserver_upcase([{ test: [:this, :that, :other] }]),
      ).to eq(TEST: [:THIS, :THAT, :OTHER])
    end

    it 'returns upcase symbol' do
      expect(
        scope.function_sqlserver_upcase([:test]),
      ).to eq(:TEST)
    end

    it 'returns mixed objects in upcease' do
      expect(
        scope.function_sqlserver_upcase([[:test, 'woot']]),
      ).to eq([:TEST, 'WOOT'])
    end
  end
end
