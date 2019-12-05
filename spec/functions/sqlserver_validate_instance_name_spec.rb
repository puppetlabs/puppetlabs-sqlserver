require 'spec_helper'

describe 'sqlserver_validate_instance_name function' do
  it 'exists' do
    expect(Puppet::Parser::Functions.function('sqlserver_validate_instance_name')).to eq('function_sqlserver_validate_instance_name')
  end

  it 'fails with over 16 characters' do
    expect { scope.function_sqlserver_validate_instance_name('ABCDEFGHIJKLMNOPQRSTUVWXYZ') }.to raise_error
  end

  it 'fails empty string' do
    expect { scope.function_sqlserver_validate_instance_name('') }.to raise_error
  end
end
