# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::role', type: :define do
  include_context 'manifests' do
    let(:sqlserver_tsql_title) { 'role-MSSQLSERVER-master-myCustomRole' }
    let(:title) { 'myCustomRole' }
  end

  context 'type =>' do
    describe 'invalid' do
      let(:additional_params) do
        {
          type: 'invalid'
        }
      end
      let(:raise_error_check) { "'type' expects" }

      it_behaves_like 'validation error'
    end

    describe 'SERVER' do
      let(:should_contain_command) do
        [
          'USE [master];',
          'CREATE SERVER ROLE [myCustomRole];',
          %r{IF NOT EXISTS\(\n\s+SELECT name FROM sys\.server_principals WHERE type_desc = 'SERVER_ROLE' AND name = 'myCustomRole'\n\)},
          "THROW 51000, 'The SERVER ROLE [myCustomRole] does not exist', 10",
        ]
      end
      let(:should_contain_onlyif) do
        [
          %r{IF NOT EXISTS\(\n\s+SELECT name FROM sys\.server_principals WHERE type_desc = 'SERVER_ROLE' AND name = 'myCustomRole'\n\)},
          "THROW 51000, 'The SERVER ROLE [myCustomRole] does not exist', 10",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end

    describe 'DATABASE' do
      let(:additional_params) do
        {
          'type' => 'DATABASE'
        }
      end
      let(:should_contain_command) do
        [
          'USE [master];',
          'CREATE ROLE [myCustomRole];',
          %r{IF NOT EXISTS\(\n\s+SELECT name FROM sys\.database_principals WHERE type_desc = 'DATABASE_ROLE' AND name = 'myCustomRole'\n\)},
          "THROW 51000, 'The DATABASE ROLE [myCustomRole] does not exist', 10",
        ]
      end
      let(:should_contain_onlyif) do
        [
          %r{IF NOT EXISTS\(\n\s+SELECT name FROM sys\.database_principals WHERE type_desc = 'DATABASE_ROLE' AND name = 'myCustomRole'\n\)},
          "THROW 51000, 'The DATABASE ROLE [myCustomRole] does not exist', 10",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end

  context 'database =>' do
    let(:additional_params) do
      {
        'database' => 'myCrazyDb'
      }
    end
    let(:sqlserver_tsql_title) { 'role-MSSQLSERVER-myCrazyDb-myCustomRole' }

    describe 'with server role type' do
      let(:raise_error_check) { 'Can not specify a database other than master when managing SERVER ROLES' }

      it_behaves_like 'validation error'
    end

    describe 'with database role type' do
      let(:additional_params) do
        {
          'database' => 'myCrazyDb',
          'type' => 'DATABASE'
        }
      end
      let(:should_contain_command) do
        [
          'USE [myCrazyDb];',
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
    end
  end

  context 'instance =>' do
    describe 'non default instance' do
      let(:params) { { instance: 'MYCUSTOM' } }

      it {
        expect(subject).to contain_sqlserver_tsql('role-MYCUSTOM-master-myCustomRole').with_instance('MYCUSTOM')
      }
    end

    describe 'empty instance' do
      let(:additional_params) { { 'instance' => '' } }
      let(:raise_error_check) { "instance' expects a String[1, 16]" }

      it_behaves_like 'validation error'
    end
  end

  context 'authorization =>' do
    describe 'undef' do
      let(:should_not_contain_command) do
        [
          %r{AUTHORIZATION}i,
          'ALTER AUTHORIZATION ON ',
        ]
      end

      it_behaves_like 'sqlserver_tsql without_command'
    end

    describe 'myUser' do
      let(:additional_params) do
        {
          authorization: 'myUser'
        }
      end
      let(:should_contain_command) do
        [
          'CREATE SERVER ROLE [myCustomRole] AUTHORIZATION [myUser];',
          'ALTER AUTHORIZATION ON SERVER ROLE::[myCustomRole] TO [myUser];',
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
    end

    describe 'myUser on Database' do
      let(:additional_params) do
        {
          authorization: 'myUser',
          type: 'DATABASE'
        }
      end
      let(:should_contain_command) do
        [
          'CREATE ROLE [myCustomRole] AUTHORIZATION [myUser];',
          'ALTER AUTHORIZATION ON ROLE::[myCustomRole] TO [myUser];',
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
    end
  end

  context 'ensure =>' do
    describe 'absent' do
      let(:additional_params) do
        {
          ensure: 'absent'
        }
      end
      let(:should_contain_command) do
        [
          'USE [master];',
          'DROP SERVER ROLE [myCustomRole];',
        ]
      end
      let(:should_contain_onlyif) do
        [
          'IF EXISTS(',
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end

  context 'members_purge =>' do
    let(:sqlserver_tsql_title) { 'role-MSSQLSERVER-master-myCustomRole-members' }

    context 'true' do
      describe 'type => SERVER and members => []' do
        let(:additional_params) do
          {
            members_purge: true
          }
        end
        let(:should_contain_command) do
          [
            "WHILE(@row <= @row_count)
BEGIN
    SET @sql = 'ALTER SERVER ROLE [myCustomRole] DROP MEMBER [' + (SELECT member FROM @purge_members WHERE ID = @row) + '];'
    EXEC(@sql)
	SET @row += 1
END",
          ]
        end
        let(:should_contain_onlyif) do
          [
            "SELECT m.name FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = 'myCustomRole'",
          ]
        end

        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end

      describe 'type => DATABASE and members => []' do
        let(:additional_params) do
          {
            type: 'DATABASE',
            members_purge: true
          }
        end
        let(:should_contain_command) do
          [
            "WHILE(@row <= @row_count)
BEGIN
    SET @sql = 'ALTER ROLE [myCustomRole] DROP MEMBER [' + (SELECT member FROM @purge_members WHERE ID = @row) + '];'
    EXEC(@sql)
	SET @row += 1
END",
          ]
        end
        let(:should_contain_onlyif) do
          [
            "SELECT m.name FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = 'myCustomRole'",
          ]
        end

        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end
    end

    describe '[test these users]' do
      let(:additional_params) do
        {
          members_purge: true,
          members: ['test', 'these', 'users']
        }
      end
      let(:should_contain_command) do
        [
          %r{WHERE r\.name = 'myCustomRole'\n\s+AND m\.name NOT IN \(},
          "NOT IN ('test','these','users')",
        ]
      end
      let(:should_contain_onlyif) do
        [
          %r{WHERE r\.name = 'myCustomRole'\n\s+AND m\.name NOT IN \(},
          "NOT IN ('test','these','users')",
        ]
      end

      it_behaves_like 'sqlserver_tsql command'
      it_behaves_like 'sqlserver_tsql onlyif'
    end
  end
end
