require 'spec_helper'

describe 'the sqlserver_validate_hash_uniq_values' do
  it 'exists' do
    expect(Puppet::Parser::Functions.function('sqlserver_validate_hash_uniq_values')).to eq('function_sqlserver_validate_hash_uniq_values')
  end

  it 'accepts mixed value types of string and string[]' do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values([{ 'test' => 'this', 'and' => ['test', 'this'] }])
    }.to raise_error
  end

  it 'passes validation' do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values([{ 'test' => 'this', 'and' => ['test', 'another'] }])
    }.not_to raise_error
  end

  it 'requires a hash' do
    expect {
      scope.function_sqlserver_validate_hash_uniq_values(['MyString'])
    }.to raise_error
  end
end
