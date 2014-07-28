require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib/puppet_x/mssql/helper'))

describe 'mssql_is_domain_user' do
  shared_examples 'when calling with' do |user, should_be_bool|
    it "with #{user} should return #{should_be_bool}" do
      Facter.stubs(:value).with(:hostname).returns('mybox')
      should run.with_params(user).and_return(should_be_bool)
    end
  end

  describe 'when calling with a local user' do
    ['mysillyuser', 'mybox\localuser'].each do |user|
      it_should_behave_like 'when calling with', user, false
    end
  end

  describe 'when calling with a system account' do
    ['NT Authority\IISUSR', 'NT Service\ManiacUser', 'nt service\mixMaxCase'].each do |user|
      it_should_behave_like 'when calling with', user, false
    end
  end

  describe 'when calling with a domain account' do
    it_should_behave_like 'when calling with', 'nexus\user', true
  end

end
