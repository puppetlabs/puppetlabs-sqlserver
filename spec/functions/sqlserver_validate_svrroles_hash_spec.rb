require 'spec_helper'
require 'puppet/error'

RSpec.describe 'sqlserver_validate_svrroles_hash function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  possible_roles = %w(sysadmin serveradmin securityadmin processadmin setupadmin bulkadmin diskadmin dbcreator)

  shared_examples 'compile' do |value|
    it {
      scope.function_sqlserver_validate_svrroles_hash([value])
    }
  end

  shared_examples 'failure' do

  end

  describe 'should validate an empty hash' do
    it_should_behave_like 'compile', {}
  end

  describe 'should compile and validate the correct hash' do
    it_should_behave_like 'compile', {'sysadmin' => 1}
  end

  describe 'should fail when invalid role' do
    let(:arguments) { [{'bogus' => 1}] }
    let(:msg) { /svrrole requires a value of/ }
    it {
      expect {
        scope.function_sqlserver_validate_svrroles_hash(arguments)
      }.to raise_error(Puppet::Error, msg)

    }
  end

  describe 'should fail with more than one parameter' do
    let(:arguments) { [{'sysadmin' => 1}, 'whoops'] }
    let(:msg) { /sqlserver_validate_svcrole_hash\(\): wrong number of arguments/ }
    it {
      expect {
        scope.function_sqlserver_validate_svrroles_hash(arguments)
      }.to raise_error(Puppet::Error, msg)
    }
  end

end
