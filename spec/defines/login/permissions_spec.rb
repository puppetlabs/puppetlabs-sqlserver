# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'manifest_shared_examples.rb'))

describe 'sqlserver::login::permissions' do
  let(:pre_condition) do
    <<-EOF
    define sqlserver::config{}
    sqlserver::config {'MSSQLSERVER': }
  EOF
  end

  context 'validation errors' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
    end
    context 'login =>' do
      let(:params) do
        {
          permissions: ['SELECT'],
        }
      end
      let(:raise_error_check) { %r{'login' expects a String.+ value} }

      describe 'missing' do
        if Puppet::Util::Package.versioncmp(Puppet.version, '4.3.0') < 0
          let(:raise_error_check) { 'Must pass login to Sqlserver::Login::Permissions[myTitle]' }
        else
          let(:raise_error_check) { "expects a value for parameter 'login'" }
        end
        it_behaves_like 'validation error'
      end
      describe 'empty' do
        let(:additional_params) { { login: '' } }

        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { { login: random_string_of_size(129) } }

        it_behaves_like 'validation error'
      end
    end
    context 'permissions' do
      let(:params) do
        {
          login: 'loggingUser',
        }
      end
      let(:raise_error_check) { %r{'permissions' .+ expects a String.+ value} }

      describe 'empty' do
        let(:additional_params) { { permissions: [''] } }

        it_behaves_like 'validation error'
      end
      describe 'under limit' do
        let(:additional_params) { { permissions: [random_string_of_size(3, false)] } }

        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { { permissions: [random_string_of_size(129, false)] } }

        it_behaves_like 'validation error'
      end
    end
    context 'state =>' do
      let(:params) do
        {
          permissions: ['SELECT'],
          login: 'loggingUser',
        }
      end

      describe 'invalid' do
        let(:additional_params) { { state: 'invalid' } }
        let(:raise_error_check) { "'state' expects" }

        it_behaves_like 'validation error'
      end
    end
  end
  context 'successfully' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
      let(:params) do
        {
          login: 'loggingUser',
          permissions: ['SELECT'],
        }
      end
    end
    ['revoke', 'grant', 'deny'].each do |state|
      context "state => '#{state}'" do
        let(:sqlserver_tsql_title) { "login-permission-MSSQLSERVER-loggingUser-#{state.upcase}" }
        let(:should_contain_command) { ["#{state.upcase} SELECT TO [loggingUser];", 'USE [master];'] }

        describe "lowercase #{state}" do
          let(:additional_params) { { state: state } }

          it_behaves_like 'sqlserver_tsql command'
        end
        state.capitalize!
        describe "capitalized #{state}" do
          let(:additional_params) { { state: state } }

          it_behaves_like 'sqlserver_tsql command'
        end
      end
    end

    context 'permission' do
      describe 'upper limit' do
        permission = random_string_of_size(128, false)
        let(:additional_params) { { permissions: [permission] } }
        let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
        let(:should_contain_command) { ['USE [master];'] }

        it_behaves_like 'sqlserver_tsql command'
      end
      describe 'alter' do
        let(:additional_params) { { permissions: ['ALTER'] } }
        let(:should_contain_command) { ['USE [master];', 'GRANT ALTER TO [loggingUser];'] }
        let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }

        it_behaves_like 'sqlserver_tsql command'
      end
    end

    describe 'Minimal Params' do
      let(:pre_condition) do
        <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
      end

      it_behaves_like 'compile'
    end
  end

  context 'command syntax' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'login-permission-MSSQLSERVER-loggingUser-GRANT' }
      let(:params) do
        {
          login: 'loggingUser',
          permissions: ['SELECT'],
        }
      end

      describe '' do
        let(:should_contain_command) do
          [
            'USE [master];',
            'GRANT SELECT TO [loggingUser];',
            %r{DECLARE @perm_state varchar\(250\)},
            %r{SET @perm_state = ISNULL\(\n\s+\(SELECT perm.state_desc FROM sys\.server_permissions perm\n\s+JOIN sys\.},
            %r{JOIN sys\.server_principals princ ON princ.principal_id = perm\.grantee_principal_id\n\s+WHERE},
            %r{WHERE princ\.type IN \('U','S','G'\)\n\s+ AND princ\.name = 'loggingUser'\n\s+AND perm\.permission_name = @permission\),\n\s+'REVOKE'\)},
            %r{SET @error_msg = 'EXPECTED login \[loggingUser\] to have permission \[' \+ @permission \+ '\] with GRANT but got ' \+ @perm_state;},
            %r{IF @perm_state != 'GRANT'\n\s+THROW 51000, @error_msg, 10},
          ]
        end

        it_behaves_like 'sqlserver_tsql command'
      end
    end
  end
end
