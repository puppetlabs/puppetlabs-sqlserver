require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'ms_sql::login', :type => :define do
  include_context 'manifests' do
    let(:mssql_tsql_title) { 'login-MSSQLSERVER-myTitle' }
    let(:title) { 'myTitle' }
    let(:params) { {
        :login => 'myTitle',
        :instance => 'MSSQLSERVER',
    } }
  end

  describe 'Minimal Params' do
    it 'it should compile' do
      should contain_mssql_tsql('login-MSSQLSERVER-myTitle')
    end
  end
  describe 'parameter assignment' do
    let(:should_contain_command) { [
        "IF exists(select * from sys.sql_logins where name = 'myTitle')",
        "@login as varchar(255) = 'myTitle'",
        '@is_disabled as tinyint = 0'
    ] }
    let(:should_contain_onlyif) { [
        "@login as varchar(255) = 'myTitle'",
        "@is_disabled as tinyint = 0",
        "@check_expiration as tinyint = 0",
        "@check_policy as tinyint = 1",
        "@type_desc as varchar(50) = 'SQL_LOGIN'",
        "@default_db as varchar(255) = 'master'",
        "@default_lang as varchar(50) = 'us_english'",
        "IF NOT EXISTS(SELECT name FROM sys.server_principals WHERE  name = 'myTitle')"
    ] }
    it_behaves_like 'mssql_tsql command'
    it_behaves_like 'mssql_tsql onlyif'
  end
end
