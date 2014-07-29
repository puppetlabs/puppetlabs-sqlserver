require 'puppet'
require 'facter'

describe Puppet::Type.type(:mssql_install) do

  shared_context 'init_args' do
    @arguments = {
        :name => 'WildName',
        :source => 'C:\myinstallexecs',
        :pid => 'areallyCrazyLongPid',
        :features => %w(SQL AS RS IS MDS),
        :instance_name => 'MYSQLSERVER_HOST',
        :agt_svc_account => 'nexus\travis',
        :agt_svc_password => 'P@ssword1',
        :as_svc_account => 'analysisAccount',
        :as_svc_password => 'CrazySimpleP@ssword',
        :is_svc_account => 'nexus\isUserAccount',
        :is_svc_password => 'isPassword@',
        :rs_svc_account => 'reportUserAccount', #always local user
        :rs_svc_password => 'reportP@ssword1',
        :sql_svc_account => 'NT Service\MSSQLSERVER',
        :sql_sysadmin_accounts => ['localAdminAccount', 'nexus\domainUser']
    }
  end

  shared_examples 'validate' do |args, success, message = 'must be set'|
    it "should evaluate to #{success}" do
      if success
        @subject = Puppet::Type.type(:mssql_install).new(args)

        @subject.stubs(:lookupvar).with('hostname').returns('machineCrazyName')
      else

      end
    end
  end
  shared_examples 'fail validation' do |args, message = 'must be set'|
    it 'should fail with' do
      expect {
        Puppet::Type.type(:mssql_install).new(args)
      }.to raise_error(Puppet::ResourceError, /#{message}/)
    end
  end

  describe 'should require sql_svc_password when local sql_svc_account' do
    include_context 'init_args'
    it_should_behave_like 'validate', @arguments, true, nil
  end

  describe 'should fail when agt_svc_account is domain user and has no password' do
    include_context 'init_args'
    @arguments.delete(:agt_svc_password)
    it_should_behave_like 'validate', @arguments, false, 'agt_svc_password required when using domain account'
  end

  describe 'should fail when is_svc_password is empty and is_svc_account is domain user' do
    include_context 'init_args'
    @arguments.delete(:is_svc_password)
    it_should_behave_like 'validate', @arguments, false, 'is_svc_password required when using domain account'
  end

  describe 'should fail when rs_svc_account contains an invalid character' do
    include_context 'init_args'
    %w(/ \ [ ] : ; | = , + * ? < > ).each do |v|
      @arguments[:rs_svc_account] = "crazy#{v}User"
      it_should_behave_like 'validate', @arguments, false, 'rs_svc_account can not contain any of the special characters,'
    end
  end
  describe 'should fail rs_svc_password being short' do
    include_context 'init_args'
    @arguments[:rs_svc_password] = 'Sh0rt^'
    it_should_behave_like 'fail validation', @arguments, 'must be at least 8 characters long'
  end

end
