# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::user', type: :define do
  include_context 'manifests' do
    let(:title) { 'loggingUser' }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-loggingUser' }
    let(:params) { { user: 'loggingUser', database: 'myDatabase' } }
    let(:pre_condition) do
      <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
    end
  end

  describe 'should fail when password above 128 characters' do
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    string = (0...129).map { o[rand(o.length)] }.join
    let(:additional_params) { { password: string } }
    let(:raise_error_check) { "'password' expects" }

    it_behaves_like 'validation error'
  end

  describe 'should fail when database above 128 characters' do
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    string = (0...129).map { o[rand(o.length)] }.join
    let(:additional_params) { { database: string } }
    let(:raise_error_check) { "'database' expects a String[1, 128]" }
    let(:sqlserver_tsql_title) { "user-MSSQLSERVER-#{string}-loggingUser" }

    it_behaves_like 'validation error'
  end

  describe 'should contain correct sql syntax for check' do
    let(:should_contain_onlyif) do
      [
        'USE [myDatabase]',
        "\nIF NOT EXISTS(SELECT name FROM sys.database_principals WHERE type in ('U','S','G') AND name = 'loggingUser')\n",
        "THROW 51000, 'User [loggingUser] does not exist for database [myDatabase]', 10\n",
      ]
    end
    let(:should_contain_command) do
      [
        'USE [myDatabase]',
        %r{CREATE USER \[loggingUser\]\n\s+FROM LOGIN \[mySysLogin\]},
      ]
    end
    let(:should_not_contain_command) do
      ['PASSWORD', 'DEFAULT_SCHEMA', 'WITH']
    end
    let(:additional_params) { { login: 'mySysLogin' } }

    it_behaves_like 'sqlserver_tsql onlyif'
    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'when a password is specified' do
    password = 'Pupp3t1@'
    let(:additional_params) { { password: password } }
    let(:should_contain_command) do
      [
        'USE [myDatabase];',
        %r{CREATE USER \[loggingUser\]\n\s+WITH PASSWORD = '#{password}'},
      ]
    end
    let(:should_not_contain_command) do
      [
        'DEFAULT_SCHEMA',
      ]
    end

    it_behaves_like 'sqlserver_tsql onlyif'
    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'when a default_schema is specified' do
    let(:additional_params) { { default_schema: 'dbo' } }
    let(:should_contain_command) do
      [
        'USE [myDatabase]',
        %r{CREATE USER \[loggingUser\]\n\s+WITH\s+DEFAULT_SCHEMA = dbo},
      ]
    end
    let(:should_not_contain_command) do
      [
        'PASSWORD',
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql without_command'
  end

  describe 'when providing windows user' do
    let(:additional_params) { { user: 'myMachineName/myUser' } }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-myMachineName/myUser' }
    let(:should_contain_command) do
      [
        'USE [myDatabase];',
        'CREATE USER [myMachineName/myUser]',
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
  end

  describe 'when providing a windows user and login' do
    let(:additional_params) { { user: 'myMachineName/myUser', login: 'myMachineName/myUser' } }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-myMachineName/myUser' }
    let(:should_contain_command) do
      [
        'USE [myDatabase]',
        /CREATE USER \[myMachineName\/myUser\]\n\s+FROM LOGIN \[myMachineName\/myUser\]/,
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
  end

  describe 'have dependency on Sqlserver::Config[MSSQLSERVER]' do
    it 'requires ::config' do
      is_expected.to contain_sqlserver_tsql(sqlserver_tsql_title).with_require('Sqlserver::Config[MSSQLSERVER]')
    end
  end

  describe 'when ensure => absent' do
    let(:additional_params) { { ensure: 'absent' } }
    let(:sqlserver_contain_command) do
      [
        'USE [loggingDb];\nDROP [loggingUser]',
        "\nIF EXISTS(SELECT name FROM sys.database_principals WHERE name = 'loggingUser')\n     THROW",
      ]
    end
    let(:sqlserver_contain_onlyif) do
      [
        "\nIF EXISTS(SELECT name FROM sys.database_principals WHERE type in ('U','S','G') AND name = 'loggingUser')\n",
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end
  context 'permissions =>' do
    let(:title) { 'myTitle' }
    let(:params) { { user: 'loggingUser', database: 'myDatabase' } }
    let(:permissions) { {} }

    shared_examples 'sqlserver_user_permissions exists' do |type|
      it {
        params[:permissions] = permissions
        type_title = ((type =~ %r{GRANT_WITH_OPTION}i) ? 'GRANT-WITH_GRANT_OPTION' : type.upcase)
        is_expected.to contain_sqlserver__user__permissions("Sqlserver::User[#{title}]-#{type_title}-loggingUser").with(
          'user' => 'loggingUser',
          'database' => 'myDatabase',
          'state' => (type == 'GRANT_WITH_OPTION') ? 'GRANT' : type.upcase,
          'with_grant_option' => type == 'GRANT_WITH_OPTION',
          'permissions' => permissions[type],
          'require' => 'Sqlserver_tsql[user-MSSQLSERVER-myDatabase-loggingUser]',
        )
      }
    end

    shared_examples 'sqlserver_user_permissions absent' do |type|
      it {
        params[:permissions] = permissions
        type_title = ((type =~ %r{GRANT_WITH_OPTION}i) ? 'GRANT-WITH_GRANT_OPTION' : type.upcase)
        is_expected.not_to contain_sqlserver__user__permissions("Sqlserver::User[#{title}]-#{type_title}-loggingUser")
      }
    end

    describe 'GRANT permissions' do
      let(:permissions) { { 'GRANT' => ['SELECT'] } }

      it_behaves_like 'sqlserver_user_permissions exists', 'GRANT'
      it_behaves_like 'sqlserver_user_permissions absent', 'DENY'
      it_behaves_like 'sqlserver_user_permissions absent', 'REVOKE'
      it_behaves_like 'sqlserver_user_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'GRANT DENY' do
      let(:permissions) { { 'GRANT' => ['CONNECT SQL'], 'DENY' => ['INSERT'] } }

      it_behaves_like 'sqlserver_user_permissions exists', 'GRANT'
      it_behaves_like 'sqlserver_user_permissions exists', 'DENY'
      it_behaves_like 'sqlserver_user_permissions absent', 'REVOKE'
      it_behaves_like 'sqlserver_user_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'GRANT_WITH_OPTION' do
      let(:permissions) { { 'GRANT_WITH_OPTION' => ['CONNECT SQL'] } }

      it_behaves_like 'sqlserver_user_permissions exists', 'GRANT_WITH_OPTION'
    end

    describe 'REVOKE' do
      let(:permissions) { { 'revoke' => ['CREATE ANY DATABASE'] } }

      it_behaves_like 'sqlserver_user_permissions exists', 'revoke'
      it_behaves_like 'sqlserver_user_permissions absent', 'GRANT'
      it_behaves_like 'sqlserver_user_permissions absent', 'DENY'
      it_behaves_like 'sqlserver_user_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'empty' do
      ['GRANT', 'DENY', 'REVOKE', 'GRANT-WITH_GRANT_OPTION'].each do |type|
        it_behaves_like 'sqlserver_user_permissions absent', type
      end
    end

    describe 'duplicate permissions' do
      let(:additional_params) do
        {
          permissions: { 'GRANT' => ['CONNECT SQL'], 'REVOKE' => ['CONNECT SQL'] },
        }
      end
      let(:raise_error_check) { "Duplicate permissions found for sqlserver::user[#{title}" }

      it_behaves_like 'validation error'
    end
  end
end
