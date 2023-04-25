# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::login', type: :define do
  include_context 'manifests' do
    let(:sqlserver_tsql_title) { 'login-MSSQLSERVER-myTitle' }
    let(:title) { 'myTitle' }
    let(:params) do
      {
        login: 'myTitle',
        instance: 'MSSQLSERVER',
      }
    end
    let(:pre_condition) do
      <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
    end
  end

  describe 'Minimal Params' do
    it 'compiles' do
      expect(subject).to contain_sqlserver_tsql('login-MSSQLSERVER-myTitle')
    end
  end

  describe 'parameter assignment' do
    let(:should_contain_command) do
      [
        "FROM sys.server_principals where name = 'myTitle'",
        '@is_disabled as tinyint = 0',
      ]
    end
    let(:should_contain_onlyif) do
      [
        "@login as varchar(255) = 'myTitle'",
        '@is_disabled as tinyint = 0',
        '@check_expiration as tinyint = 0',
        '@check_policy as tinyint = 1',
        "@type_desc as varchar(50) = 'SQL_LOGIN'",
        "@default_db as varchar(255) = 'master'",
        "@default_lang as varchar(50) = 'us_english'",
        "FROM sys.server_principals WHERE name = 'myTitle'",
      ]
    end

    it_behaves_like 'sqlserver_tsql command'
    it_behaves_like 'sqlserver_tsql onlyif'
  end

  describe 'check_policy' do
    let(:additional_params) { { check_policy: false, check_expiration: true } }
    let(:raise_error_check) { 'Can not have check expiration enabled when check_policy is disabled' }

    it_behaves_like 'validation error'
  end

  context 'permissions =>' do
    let(:title) { 'myTitle' }
    let(:params) do
      {
        login: 'myLogin',
      }
    end
    let(:permissions) { {} }

    shared_examples 'sqlserver_permissions exists' do |type|
      it {
        params[:permissions] = permissions
        type_title = ((type =~ %r{GRANT_WITH_OPTION}i) ? 'GRANT-WITH_GRANT_OPTION' : type.upcase)
        expect(subject).to contain_sqlserver__login__permissions("Sqlserver::Login[#{title}]-#{type_title}-myLogin").with(
          'login' => 'myLogin',
          'state' => (type == 'GRANT_WITH_OPTION') ? 'GRANT' : type.upcase,
          'with_grant_option' => type == 'GRANT_WITH_OPTION',
          'permissions' => permissions[type],
          'require' => 'Sqlserver_tsql[login-MSSQLSERVER-myLogin]',
        )
      }
    end

    shared_examples 'sqlserver_permissions absent' do |type|
      it {
        params[:permissions] = permissions
        type_title = ((type =~ %r{GRANT_WITH_OPTION}i) ? 'GRANT-WITH_GRANT_OPTION' : type.upcase)
        expect(subject).not_to contain_sqlserver__login__permissions("Sqlserver::Login[#{title}]-#{type_title}-myLogin")
      }
    end

    describe 'GRANT permissions' do
      let(:permissions) { { 'GRANT' => ['SELECT'] } }

      it_behaves_like 'sqlserver_permissions exists', 'GRANT'
      it_behaves_like 'sqlserver_permissions absent', 'DENY'
      it_behaves_like 'sqlserver_permissions absent', 'REVOKE'
      it_behaves_like 'sqlserver_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'GRANT DENY' do
      let(:permissions) { { 'GRANT' => ['CONNECT SQL'], 'DENY' => ['INSERT'] } }

      it_behaves_like 'sqlserver_permissions exists', 'GRANT'
      it_behaves_like 'sqlserver_permissions exists', 'DENY'
      it_behaves_like 'sqlserver_permissions absent', 'REVOKE'
      it_behaves_like 'sqlserver_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'GRANT_WITH_OPTION' do
      let(:permissions) { { 'GRANT_WITH_OPTION' => ['CONNECT SQL'] } }

      it_behaves_like 'sqlserver_permissions exists', 'GRANT_WITH_OPTION'
    end

    describe 'REVOKE' do
      let(:permissions) { { 'revoke' => ['CREATE ANY DATABASE'] } }

      it_behaves_like 'sqlserver_permissions exists', 'revoke'
      it_behaves_like 'sqlserver_permissions absent', 'GRANT'
      it_behaves_like 'sqlserver_permissions absent', 'DENY'
      it_behaves_like 'sqlserver_permissions absent', 'GRANT_WITH_OPTION'
    end

    describe 'empty' do
      ['GRANT', 'DENY', 'REVOKE', 'GRANT-WITH_GRANT_OPTION'].each do |type|
        it_behaves_like 'sqlserver_permissions absent', type
      end
    end

    describe 'duplicate permissions' do
      let(:additional_params) do
        {
          permissions: { 'GRANT' => ['CONNECT SQL'], 'REVOKE' => ['CONNECT SQL'] },
        }
      end
      let(:raise_error_check) { "Duplicate permissions found for sqlserver::login[#{title}" }

      it_behaves_like 'validation error'
    end
  end
end
