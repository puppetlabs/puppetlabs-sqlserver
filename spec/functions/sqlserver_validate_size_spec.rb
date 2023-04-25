# frozen_string_literal: true

require 'spec_helper'
require 'puppet/error'

describe 'sqlserver_validate_size function' do
  shared_examples 'should compile' do |value|
    it "with a value #{value}" do
      scope.function_sqlserver_validate_size([value])
    end
  end

  shared_examples 'should raise error' do |value, error_re|
    it {
      expect { scope.function_sqlserver_validate_size([value]) }.to raise_error(Puppet::ParseError, error_re)
    }
  end

  it 'exists' do
    expect(Puppet::Parser::Functions.function('sqlserver_validate_size')).to eq('function_sqlserver_validate_size')
  end

  describe 'should raise error when no arguments passed' do
    it {
      expect { scope.function_sqlserver_validate_size([]) }.to raise_error(Puppet::ParseError, %r{requires exactly 1 argument})
    }
  end

  ['KB', 'MB', 'TB'].each do |measure|
    context "when calling with #{measure}" do
      describe 'and valid value' do
        it_behaves_like 'should compile', "2#{measure}"
      end

      describe 'when giving a decimal value' do
        it_behaves_like 'should raise error', "0.2#{measure}", %r{Number must be an integer}
      end

      describe 'when giving a value larger than 2147483647' do
        it_behaves_like 'should raise error', "2147483648#{measure}", %r{Please use larger measurement for values greater than 2147483647}
      end
    end
  end
end
