require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'mssql::sp_configure', :type => :define do
  include_context 'manifests' do
    let(:title) { 'filestream access level' }
    let(:mssql_tsql_title) { 'sp_configure-MSSQLSERVER-filestream access level' }
    let(:params) { {
        :config_name => 'filestream access level',
        :value => 1,
    } }
  end
  describe 'basic usage' do
    let(:should_contain_command) { [
        "EXECUTE @return_value = sp_configure @configname = N'filestream access level', @configvalue = 1",
        "IF @return_value != 0
	THROW 51000,'Unable to update `filestream access level`', 10",
        'RECONFIGURE'
    ] }
    let(:should_contain_onlyif) { [
        "INSERT INTO @sp_conf EXECUTE sp_configure @configname = N'filestream access level'",
        "IF NOT EXISTS(select * from @sp_conf where name = 'filestream access level' AND run_value != 1)
	THROW 51000, 'sp_configure `filestream access level` is not in the correct state', 10"
    ] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql onlyif'
  end

  describe 'reconfigure => false' do
    let(:additional_params) { {
        :reconfigure => false,
    } }
    let(:should_not_contain_command) { [
        'RECONFIGURE WITH OVERRIDE',
        'RECONFIGURE'
    ] }
    it_behaves_like 'mssql_tsql without_command'
  end

  describe 'reconfigure => false' do
    let(:additional_params) { {
        :with_override => false,
    } }
    let(:should_not_contain_command) { [
        'RECONFIGURE WITH OVERRIDE',
    ] }
    let(:should_contain_command) { ['RECONFIGURE'] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql without_command'
  end

  describe 'service' do
    it 'should be defined' do
      should contain_service('MSSQLSERVER')
    end
    it 'should not subscribe to mssql::config by default' do
      should_not contain_service('MSSQLSERVER').that_subscribes_to('Mssql::Sp_configure[filestream access level]')
    end
    it 'should notify service when specifying restart' do
      params.merge!({:restart => true})
      should contain_service('MSSQLSERVER').that_subscribes_to('Mssql::Sp_configure[filestream access level]')
    end
    it 'should correctly identify service that is not MSSQLSERVER' do
      params.merge!({:instance => 'ALTINSTANCE'})
      should contain_service('MSSQL$ALTINSTANCE')
    end
    it 'should correctly identify service that is not MSSQLSERVER' do
      params.merge!({:instance => 'ALTINSTANCE', :restart => true})
      should contain_service('MSSQL$ALTINSTANCE').that_subscribes_to('Mssql::Sp_configure[filestream access level]')
    end
  end
end
