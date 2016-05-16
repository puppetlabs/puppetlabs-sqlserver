require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::role', :type => :define do
  include_context 'manifests' do
    let(:sqlserver_tsql_title) { 'role-MSSQLSERVER-master-myCustomRole' }
    let(:title) { 'myCustomRole' }
  end

  context 'type =>' do
    describe 'invalid' do
      let(:additional_params) { {
        :type => 'invalid',
      } }
      let(:raise_error_check) { "Type must be either 'SERVER' or 'DATABASE', provided 'invalid'" }
      it_behaves_like 'validation error'
    end
    describe 'SERVER' do
      let(:should_contain_command) { [
        'USE [master];',
        'CREATE SERVER ROLE [myCustomRole];',
        /IF NOT EXISTS\(\n\s+SELECT name FROM sys\.server_principals WHERE type_desc = 'SERVER_ROLE' AND name = 'myCustomRole'\n\)/,
        "THROW 51000, 'The SERVER ROLE [myCustomRole] does not exist', 10"
      ] }
      let(:should_contain_onlyif) { [
        /IF NOT EXISTS\(\n\s+SELECT name FROM sys\.server_principals WHERE type_desc = 'SERVER_ROLE' AND name = 'myCustomRole'\n\)/,
        "THROW 51000, 'The SERVER ROLE [myCustomRole] does not exist', 10"
      ] }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
    describe 'DATABASE' do
      let(:additional_params) { {
        'type' => 'DATABASE',
      } }
      let(:should_contain_command) { [
        'USE [master];',
        'CREATE ROLE [myCustomRole];',
        /IF NOT EXISTS\(\n\s+SELECT name FROM sys\.database_principals WHERE type_desc = 'DATABASE_ROLE' AND name = 'myCustomRole'\n\)/,
        "THROW 51000, 'The DATABASE ROLE [myCustomRole] does not exist', 10"
      ] }
      let(:should_contain_onlyif) { [
        /IF NOT EXISTS\(\n\s+SELECT name FROM sys\.database_principals WHERE type_desc = 'DATABASE_ROLE' AND name = 'myCustomRole'\n\)/,
        "THROW 51000, 'The DATABASE ROLE [myCustomRole] does not exist', 10",
      ] }

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'

    end
  end

  context 'database =>' do
    let(:additional_params) { {
      'database' => 'myCrazyDb',
    } }
    let(:sqlserver_tsql_title) { 'role-MSSQLSERVER-myCrazyDb-myCustomRole' }
    describe 'with server role type' do
      let(:raise_error_check) { 'Can not specify a database other than master when managing SERVER ROLES' }
      it_behaves_like 'validation error'
    end
    describe 'with database role type' do
      let(:additional_params) { {
        'database' => 'myCrazyDb',
        'type' => 'DATABASE',
      } }
      let(:should_contain_command) { [
        'USE [myCrazyDb];',
      ] }
      it_behaves_like 'sqlserver_tsql command'
    end
  end

  context 'instance =>' do
    describe 'non default instance' do
      let(:params) { {:instance => 'MYCUSTOM'} }
      it {
        should contain_sqlserver_tsql('role-MYCUSTOM-master-myCustomRole').with_instance('MYCUSTOM')
      }
    end
    describe 'empty instance' do
      let(:additional_params) { {'instance' => ''} }
      let(:raise_error_check) { 'Instance name must be between 1 to 16 characters' }
      it_behaves_like 'validation error'
    end
  end

  context 'authorization =>' do
    describe 'undef' do
      let(:should_not_contain_command) { [
        /AUTHORIZATION/i,
        'ALTER AUTHORIZATION ON ',
      ] }
      it_behaves_like 'sqlserver_tsql without_command'
    end
    describe 'myUser' do
      let(:additional_params) { {
        :authorization => 'myUser',
      } }
      let(:should_contain_command) { [
        'CREATE SERVER ROLE [myCustomRole] AUTHORIZATION [myUser];',
        'ALTER AUTHORIZATION ON SERVER ROLE::[myCustomRole] TO [myUser];'
      ] }
      it_behaves_like 'sqlserver_tsql command'
    end
    describe 'myUser on Database' do
      let(:additional_params) { {
        :authorization => 'myUser',
        :type => 'DATABASE',
      } }
      let(:should_contain_command) { [
        'CREATE ROLE [myCustomRole] AUTHORIZATION [myUser];',
        'ALTER AUTHORIZATION ON ROLE::[myCustomRole] TO [myUser];'
      ] }
      it_behaves_like 'sqlserver_tsql command'
    end
  end

  context 'ensure =>' do
    describe 'absent' do
      let(:additional_params) { {
        :ensure => 'absent',
      } }
      let(:should_contain_command) { [
        'USE [master];',
        'DROP SERVER ROLE [myCustomRole];'
      ] }
      let(:should_contain_onlyif) { [
        'IF EXISTS(',
      ] }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end

  context 'members =>' do
    let(:sqlserver_tsql_title) { 'role-myCustomRole-members' }
    describe '[test these users]' do
      let(:additional_params) { {
        :members => %w(test these users),
      } }
      let(:should_contain_command) { [
        'ALTER SERVER ROLE [myCustomRole] ADD MEMBER [test];',
        'ALTER SERVER ROLE [myCustomRole] ADD MEMBER [these];',
        'ALTER SERVER ROLE [myCustomRole] ADD MEMBER [users];',
      ] }
      let(:should_contain_onlyif) { [
      ] }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
    describe 'empty' do
      it {
        should_not contain_sqlserver_tsql(sqlserver_tsql_title)
      }
    end
  end
  context 'members_purge =>' do
    let(:sqlserver_tsql_title) { 'role-myCustomRole-members' }
    context 'true' do
      describe 'type => SERVER and members => []' do
        let(:additional_params) { {
          :members_purge => true,
        } }
        let(:should_contain_command) { [
          "WHILE(@row <= @row_count)
BEGIN
    SET @sql = 'ALTER SERVER ROLE [myCustomRole] DROP MEMBER [' + (SELECT member FROM @purge_members WHERE ID = @row) + '];'
    EXEC(@sql)
	SET @row += 1
END"
        ] }
        let(:should_contain_onlyif) { [
          "DECLARE @purge_members TABLE (
ID int IDENTITY(1,1),
member varchar(128)
)",
          "INSERT INTO @purge_members (member) (
SELECT m.name FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
	JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
	WHERE r.name = 'myCustomRole'",
          "IF 0 != (SELECT COUNT(*) FROM @purge_members)
    THROW 51000, 'Unlisted Members in Role, will be purged', 10",
        ] }
        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end

      describe 'type => DATABASE and members => []' do
        let(:additional_params) { {
          :type => 'DATABASE',
          :members_purge => true,
        } }
        let(:should_contain_command) { [
          "WHILE(@row <= @row_count)
BEGIN
    SET @sql = 'ALTER ROLE [myCustomRole] DROP MEMBER [' + (SELECT member FROM @purge_members WHERE ID = @row) + '];'
    EXEC(@sql)
	SET @row += 1
END"
        ] }
        let(:should_contain_onlyif) { [
          "DECLARE @purge_members TABLE (
ID int IDENTITY(1,1),
member varchar(128)
)",
          "INSERT INTO @purge_members (member) (
SELECT m.name FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
	JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
	WHERE r.name = 'myCustomRole'",
          "IF 0 != (SELECT COUNT(*) FROM @purge_members)
    THROW 51000, 'Unlisted Members in Role, will be purged', 10",
        ] }
        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end
    end
    describe '[test these users]' do
      let(:additional_params) { {
        :members_purge => true,
        :members => %w(test these users),
      } }
      let(:should_contain_command) { [
        /WHERE r\.name = 'myCustomRole'\n\s+AND m\.name NOT IN \(/,
        "NOT IN ('test','these','users')"
      ] }
      let(:should_contain_onlyif) { [
        /WHERE r\.name = 'myCustomRole'\n\s+AND m\.name NOT IN \(/,
        "NOT IN ('test','these','users')"
      ] }
      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end
end
