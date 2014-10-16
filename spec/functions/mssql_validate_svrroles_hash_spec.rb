require 'spec_helper'
require 'puppet/error'

describe 'mssql_validate_svrroles_hash function' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  possible_roles = %w(sysadmin serveradmin securityadmin processadmin setupadmin bulkadmin diskadmin dbcreator)

  shared_examples 'compile' do |value|
    it {
      scope.function_mssql_validate_svrroles_hash([value])
    }
  end

  describe 'should validate an empty hash' do
    it_should_behave_like 'compile', {}
  end

  describe 'should compile and validate the correct hash' do
    it_should_behave_like 'compile', {'sysadmin' => 1}
  end

end
