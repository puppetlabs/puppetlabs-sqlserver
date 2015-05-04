require 'spec_helper'

RSpec.describe 'sqlserver::role::permissions' do
  include_context 'manifests' do
    let(:title) { 'myTitle' }
    let(:sqlserver_tsql_title) { 'role-permissions-myCustomRole-GRANT-MSSQLSERVER' }
    let(:params) { {
        :role => 'myCustomRole',
        :permissions => %w(INSERT UPDATE DELETE SELECT),
    } }
  end

  context 'sql variables' do
    let(:params) { {
        :role => 'myCustomRole',
        :permissions => %w(INSERT UPDATE DELETE SELECT),
    } }
    declare_variables = [
        "DECLARE
    @perm_state varchar(250),
    @error_msg varchar(250),
    @permission varchar(250),
    @princ_name varchar(50),
    @princ_type varchar(50),
    @state_desc varchar(50);",
        "SET @princ_type = 'SERVER_ROLE';",
        "SET @princ_name = 'myCustomRole';",
        "SET @state_desc = 'GRANT';"]
    let(:should_contain_command) { declare_variables }
    let(:should_contain_onlyif) { declare_variables }
    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end

  context 'type =>' do
    shared_examples 'GRANT Permissions' do |type|
      base_commands = [
          "SET @princ_type = '#{type.upcase}_ROLE';",
          "ISNULL(
	(SELECT state_desc FROM sys.#{type.downcase}_permissions prem
		JOIN sys.#{type.downcase}_principals r ON r.principal_id = prem.grantee_principal_id
		WHERE r.name = @princ_name AND r.type_desc = @princ_type
		AND prem.permission_name = @permission),
	 'REVOKE')",
          "SET @permission = 'INSERT';",
          "SET @permission = 'UPDATE';",
          "SET @permission = 'DELETE';",
          "SET @permission = 'SELECT';",
      ]
      should_commands = [
          "GRANT INSERT TO [myCustomRole];",
          "GRANT UPDATE TO [myCustomRole];",
          "GRANT DELETE TO [myCustomRole];",
          "GRANT SELECT TO [myCustomRole];"
      ]
      let(:should_contain_command) { base_commands + should_commands }
      let(:should_contain_onlyif) { base_commands }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end

    describe 'DATABASE' do
      let(:additional_params) { {
          :type => 'DATABASE',
      } }
      it_behaves_like 'GRANT Permissions', 'database'
    end

    describe 'SERVER' do
      let(:additional_params) { {
          :type => 'SERVER',
      } }
      it_behaves_like 'GRANT Permissions', 'server'
    end
  end

  context 'permissions =>' do
    describe '[INSERT UPDATE DELETE SELECT]' do
      declare_variables = [
          "SET @permission = 'INSERT';",
          "SET @permission = 'UPDATE';",
          "SET @permission = 'DELETE';",
          "SET @permission = 'SELECT';",
      ]
      let(:should_contain_command) { declare_variables +
          [
              "GRANT INSERT TO [myCustomRole];",
              "GRANT UPDATE TO [myCustomRole];",
              "GRANT DELETE TO [myCustomRole];",
              "GRANT SELECT TO [myCustomRole];"
          ] }
      let(:should_contain_onlyif) { declare_variables }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
    describe '[]' do
      let(:params) { {
          :role => 'myCustomRole',
          :permissions => []
      } }
      it {
        should compile
        should_not contain_sqlserver_tsql(sqlserver_tsql_title)
      }
    end
  end

  context 'database =>' do
    describe 'default' do
      let(:should_contain_command) { ['USE [master];'] }
      let(:should_contain_onlyif) { ['USE [master];'] }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
    describe 'customDatabase' do
      let(:additional_params) { {:database => 'customDatabase'} }
      let(:should_contain_command) { ['USE [customDatabase];'] }
      it_behaves_like 'sqlserver_tsql command'
      let(:should_contain_onlyif) { ['USE [customDatabase];'] }
      it_behaves_like 'sqlserver_tsql onlyif'
      let(:should_contain_without_command) { ['USE [master];'] }
      it_behaves_like 'sqlserver_tsql without_command'
      let(:should_contain_without_onlyif) { ['USE [master];'] }
      it_behaves_like 'sqlserver_tsql without_onlyif'
    end
  end

  context 'instance =>' do
    ['MSSQLSERVER', 'MYINSTANCE'].each do |instance|
      describe "should contain #{instance} for sqlserver_tsql" do
        let(:params) { {
            :role => 'myCustomRole',
            :permissions => %w(INSERT UPDATE DELETE SELECT),
            :instance => instance
        } }
        it {
          should contain_sqlserver_tsql("role-permissions-myCustomRole-GRANT-#{instance}").with_instance(instance)
        }
      end
    end
  end

end
