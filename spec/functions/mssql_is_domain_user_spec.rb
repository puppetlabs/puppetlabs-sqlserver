require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib/puppet_x/mssql/server_helper'))


RSpec.describe 'mssql_is_domain_user' do
  shared_examples 'return the value' do
    let(:scope) { PuppetlabsSpec::PuppetInternals.scope }
    it {
      Facter.stubs(:value).with(anything())
      Facter.stubs(:value).with(:hostname).returns('mybox')
      expect(scope.function_mssql_is_domain_user([user])).to eq(expected_value)
    }
  end

  ['mysillyuser', 'mybox\localuser'].each do |user|
    describe "when calling with a local user #{user}" do
      it_should_behave_like 'return the value' do
        let(:expected_value) { false }
        let(:user) { user }
      end
    end
  end


  ['NT Authority\IISUSR', 'NT Service\ManiacUser', 'nt service\mixMaxCase'].each do |user|
    describe "when calling with a system account #{user}" do
      it_should_behave_like 'return the value' do
        let(:user) { user }
        let(:expected_value) { false }
      end
    end
  end

  describe 'when calling with a domain account \'nexus\user\'' do
    it_should_behave_like 'return the value' do
      let(:user) { 'nexus\user' }
      let(:expected_value) { true }
    end
  end

end
