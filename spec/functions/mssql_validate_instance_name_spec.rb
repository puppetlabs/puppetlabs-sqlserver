require 'spec_helper'

describe 'mssql_validate_instance_name function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
  it 'should exist' do
    expect(Puppet::Parser::Functions.function("mssql_validate_instance_name")).to eq("function_mssql_validate_instance_name")
  end
  it 'should fail with over 16 characters' do
    expect { scope.function_mssql_validate_instance_name('ABCDEFGHIJKLMNOPQRSTUVWXYZ') }.to raise_error
  end

end
