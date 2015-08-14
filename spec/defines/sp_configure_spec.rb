require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::sp_configure', :type => :define do
  include_context 'manifests' do
    let(:title) { 'filestream access level' }
    let(:sqlserver_tsql_title) { 'sp_configure-MSSQLSERVER-filestream access level' }
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
        "IF EXISTS(select * from @sp_conf where name = 'filestream access level' AND run_value != 1)
	THROW 51000, 'sp_configure `filestream access level` is not in the correct state', 10"
    ] }
    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end

  describe 'reconfigure => false' do
    let(:additional_params) { {
        :reconfigure => false,
    } }
    let(:should_not_contain_command) { [
        'RECONFIGURE WITH OVERRIDE',
        'RECONFIGURE'
    ] }
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'reconfigure => invalid' do
    let(:additional_params) { {:reconfigure => 'invalid'} }
    let(:raise_error_check) {'"invalid" is not a boolean.  It looks to be a String'}
    it_behaves_like 'validation error'
  end

  describe 'restart => invalid' do
    let(:additional_params) { {:restart => 'invalid'} }
    let(:raise_error_check) {'"invalid" is not a boolean.  It looks to be a String'}
    it_behaves_like 'validation error'
  end

  describe 'with_override => false' do
    let(:additional_params) { {
        :with_override => false,
    } }
    let(:should_not_contain_command) { [
        'RECONFIGURE WITH OVERRIDE',
    ] }
    let(:should_contain_command) { ['RECONFIGURE'] }
    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'with_override => invalid' do
    let(:additional_params) { {:with_override => 'invalid'} }
    let(:raise_error_check) {'"invalid" is not a boolean.  It looks to be a String'}
    it_behaves_like 'validation error'
  end

  describe 'service' do
    it 'should be defined' do
      should contain_service('MSSQLSERVER')
    end
  end
end
