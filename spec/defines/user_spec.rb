require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::user', :type => :define do
  include_context 'manifests' do
    let(:title) { 'loggingUser' }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-loggingUser' }
    let(:params) { {:user => 'loggingUser', :database => 'myDatabase'} }
  end

  describe 'should fail when password above 128 characters' do
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten
    string = (0...129).map { o[rand(o.length)] }.join
    let(:additional_params) { {:password => string} }
    let(:raise_error_check) { 'Password must be equal or less than 128 characters' }
    it_should_behave_like 'validation error'
  end

  describe 'should fail when database above 128 characters' do
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten
    string = (0...129).map { o[rand(o.length)] }.join
    let(:additional_params) { {:database => string} }
    let(:raise_error_check) { 'Database name must be between 1 and 128 characters' }
    let(:sqlserver_tsql_title) { "user-MSSQLSERVER-#{string}-loggingUser" }
    it_should_behave_like 'validation error'
  end

  describe 'should contain correct sql syntax for check' do
    let(:should_contain_onlyif) { [
        "USE [myDatabase]",
        "\nIF NOT EXISTS(SELECT name FROM sys.database_principals WHERE type in ('U','S','G') AND name = 'loggingUser')\n",
        "THROW 51000, 'User [loggingUser] does not exist for database [myDatabase]', 10\n"
    ] }
    let(:should_contain_command) { [
        "USE [myDatabase]",
        /CREATE USER \[loggingUser\]\n\s+FROM LOGIN \[mySysLogin\]/
    ] }
    let(:should_not_contain_command) { [
        'PASSWORD',
        'DEFAULT_SCHEMA',
        'WITH'
    ] }
    let(:additional_params) { {:login => 'mySysLogin'} }
    it_should_behave_like 'sqlserver_tsql onlyif'
    it_should_behave_like 'sqlserver_tsql command'
    it_should_behave_like 'sqlserver_tsql without_command'
  end

  describe 'when a password is specified' do
    password = 'Pupp3t1@'
    let(:additional_params) { {:password => password} }
    let(:should_contain_command) { [
        "USE [myDatabase];",
        /CREATE USER \[loggingUser\]\n\s+WITH PASSWORD = '#{password}'/
    ] }
    let(:should_not_contain_command) { [
        'DEFAULT_SCHEMA',
    ] }
    it_should_behave_like 'sqlserver_tsql onlyif'
    it_should_behave_like 'sqlserver_tsql command'
    it_should_behave_like 'sqlserver_tsql without_command'
  end

  describe 'when a default_schema is specified' do
    let(:additional_params) { {:default_schema => 'dbo'} }
    let(:should_contain_command) { [
        "USE [myDatabase]",
        /CREATE USER \[loggingUser\]\n\s+WITH\s+DEFAULT_SCHEMA = dbo/
    ] }
    let(:should_not_contain_command) { [
        'PASSWORD',
    ] }
    it_should_behave_like 'sqlserver_tsql command'
    it_should_behave_like 'sqlserver_tsql without_command'
  end

  describe 'when providing windows user' do
    let(:additional_params) { {:user => 'myMachineName/myUser'} }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-myMachineName/myUser' }
    let(:should_contain_command) { [
        "USE [myDatabase]",
        'CREATE USER [myMachineName/myUser]'
    ] }
    it_should_behave_like 'sqlserver_tsql command'
  end

  describe 'when providing a windows user and login' do
    let(:additional_params) { {:user => 'myMachineName/myUser', :login => 'myMachineName/myUser'} }
    let(:sqlserver_tsql_title) { 'user-MSSQLSERVER-myDatabase-myMachineName/myUser' }
    let(:should_contain_command) { [
        "USE [myDatabase]",
        /CREATE USER \[myMachineName\/myUser\]\n\s+FROM LOGIN \[myMachineName\/myUser\]/
    ] }
    it_should_behave_like 'sqlserver_tsql command'
  end
  describe 'have dependency on Sqlserver::Config[MSSQLSERVER]' do
    it 'should require ::config' do
      should contain_sqlserver_tsql(sqlserver_tsql_title).with_require('Sqlserver::Config[MSSQLSERVER]')
    end
  end
end
