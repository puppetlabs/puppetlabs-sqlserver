require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'manifest_shared_examples.rb'))

describe 'sqlserver::login::permissions' do
  let(:facts) { {:osfamily => 'windows'} }
  context 'validation errors' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
    end
    context 'login =>' do
      let(:params) { {
        :permissions => ['SELECT'],
      } }
      let(:raise_error_check) { 'Login must be between 1 and 128 characters' }
      describe 'missing' do
        if Puppet.version < '4.0.0'
          let(:raise_error_check) { 'Must pass login to Sqlserver::Login::Permissions[myTitle]' }
        else
          let(:raise_error_check) { "expects a value for parameter 'login'" }
        end
        it_behaves_like 'validation error'
      end
      describe 'empty' do
        let(:additional_params) { {:login => ''} }
        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { {:login => random_string_of_size(129)} }
        it_behaves_like 'validation error'
      end
    end
    context 'permission' do
      let(:params) { {
        :login => 'loggingUser',
      } }
      let(:raise_error_check) { 'Permission must be between 4 and 128 characters' }
      describe 'empty' do
        let(:additional_params) { {:permissions => ['']} }
        it_behaves_like 'validation error'
      end
      describe 'under limit' do
        let(:additional_params) { {:permissions => [random_string_of_size(3, false)]} }
        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { {:permissions => [random_string_of_size(129, false)]} }
        it_behaves_like 'validation error'
      end
    end
    context 'state =>' do
      let(:params) { {
        :permissions => ['SELECT'],
        :login => 'loggingUser'
      } }
      describe 'invalid' do
        let(:additional_params) { {:state => 'invalid'} }
        let(:raise_error_check) { "State parameter can only be one of 'GRANT', 'REVOKE' or 'DENY', you passed a value of invalid" }
        it_behaves_like 'validation error'
      end
    end
  end
  context 'successfully' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
      let(:params) { {
        :login => 'loggingUser',
        :permissions => ['SELECT'],
      } }
    end
    %w(revoke grant deny).each do |state|
      context "state => '#{state}'" do
        let(:sqlserver_tsql_title) { "login-permission-MSSQLSERVER-loggingUser-#{state.upcase}" }
        let(:should_contain_command) { ["#{state.upcase} SELECT TO [loggingUser];", 'USE [master];'] }
        describe "lowercase #{state}" do
          let(:additional_params) { {:state => state} }
          it_behaves_like 'sqlserver_tsql command'
        end
        state.capitalize!
        describe "capitalized #{state}" do
          let(:additional_params) { {:state => state} }
          it_behaves_like 'sqlserver_tsql command'
        end
      end
    end

    context 'permission' do
      describe 'upper limit' do
        permission =random_string_of_size(128, false)
        let(:additional_params) { {:permissions => [permission]} }
        let(:sqlserver_tsql_title) { "login-permission-MSSQLSERVER-loggingUser-GRANT" }
        let(:should_contain_command) { ['USE [master];'] }
        it_behaves_like 'sqlserver_tsql command'
      end
      describe 'alter' do
        let(:additional_params) { {:permissions => ['ALTER']} }
        let(:should_contain_command) { ['USE [master];', 'GRANT ALTER TO [loggingUser];'] }
        let(:sqlserver_tsql_title) { "login-permission-MSSQLSERVER-loggingUser-GRANT" }
        it_behaves_like 'sqlserver_tsql command'
      end
    end

    describe 'Minimal Params' do
      let(:pre_condition) { <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
      }
      it_behaves_like 'compile'
    end

  end

  context 'command syntax' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
      let(:params) { {
        :login => 'loggingUser',
        :permissions => ['SELECT'],
      } }
      describe '' do
        let(:should_contain_command) { [
          'USE [master];',
          'GRANT SELECT TO [loggingUser];',
          /DECLARE @perm_state varchar\(250\)/,
          /SET @perm_state = ISNULL\(\n\s+\(SELECT perm.state_desc FROM sys\.server_permissions perm\n\s+JOIN sys\./,
          /JOIN sys\.server_principals princ ON princ.principal_id = perm\.grantee_principal_id\n\s+WHERE/,
          /WHERE princ\.type IN \('U','S','G'\)\n\s+ AND princ\.name = 'loggingUser'\n\s+AND perm\.permission_name = @permission\),\n\s+'REVOKE'\)/,
          /SET @error_msg = 'EXPECTED login \[loggingUser\] to have permission \[' \+ @permission \+ '\] with GRANT but got ' \+ @perm_state;/,
          /IF @perm_state != 'GRANT'\n\s+THROW 51000, @error_msg, 10/
        ] }
        it_behaves_like 'sqlserver_tsql command'
      end
    end
  end

end
