# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'manifest_shared_examples.rb'))

describe 'sqlserver::user::permissions' do
  let(:pre_condition) do
    <<-EOF
    define sqlserver::config{}
    sqlserver::config {'MSSQLSERVER': }
    EOF
  end

  context 'validation errors' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT' }
    end
    context 'user =>' do
      let(:params) do
        {
          permissions: ['SELECT'],
          database: 'loggingDb',
        }
      end
      let(:raise_error_check) { "'user' expects a String[1, 128] value" }

      describe 'missing' do
        let(:raise_error_check) { "expects a value for parameter 'user'" }

        it_behaves_like 'validation error'
      end

      describe 'empty' do
        let(:additional_params) { { user: '' } }

        it_behaves_like 'validation error'
      end

      describe 'over limit' do
        let(:additional_params) { { user: random_string_of_size(129) } }

        it_behaves_like 'validation error'
      end
    end

    context 'permissions' do
      let(:params) do
        {
          user: 'loggingUser',
          database: 'loggingDb',
        }
      end
      let(:raise_error_check) { %r{'permissions' .+ expects a String.+ value} }

      describe 'empty' do
        let(:additional_params) { { permissions: '' } }
        let(:raise_error_check) { %r{'permissions' expects an Array value} }

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
          database: 'loggingDb',
          user: 'loggingUser',
        }
      end

      describe 'invalid' do
        let(:additional_params) { { state: 'invalide' } }
        let(:raise_error_check) { "'state' expects" }

        it_behaves_like 'validation error'
      end
    end

    context 'with_grant_option => ' do
      let(:params) do
        {
          permissions: ['SELECT'],
          database: 'loggingDb',
          user: 'loggingUser',
        }
      end

      describe 'true AND state => DENY' do
        let(:additional_params) { { with_grant_option: true, state: 'DENY' } }
        let(:raise_error_check) { "Can not use with_grant_option and state DENY, must be 'GRANT' " }

        it_behaves_like 'validation error'
      end

      describe 'invalid' do
        let(:additional_params) { { with_grant_option: 'invalid' } }
        let(:raise_error_check) { "'with_grant_option' expects" }

        it_behaves_like 'validation error'
      end
    end
  end

  context 'successfully' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT' }
      let(:params) do
        {
          user: 'loggingUser',
          permissions: ['SELECT'],
          database: 'loggingDb',
        }
      end
    end
    ['revoke', 'grant', 'deny'].each do |state|
      context "state => '#{state}'" do
        let(:sqlserver_tsql_title) { "user-permissions-MSSQLSERVER-loggingDb-loggingUser-#{state.upcase}" }
        let(:should_contain_command) { ["#{state.upcase} SELECT TO [loggingUser];", 'USE [loggingDb];'] }

        describe "lowercase #{state}" do
          let(:additional_params) { { state: state } }

          it_behaves_like 'sqlserver_tsql command'
        end

        state = state.capitalize
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
        let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT' }
        let(:should_contain_command) { ['USE [loggingDb];'] }

        it_behaves_like 'sqlserver_tsql command'
      end

      describe 'alter' do
        let(:additional_params) { { permissions: ['ALTER'] } }
        let(:should_contain_command) { ['USE [loggingDb];', 'GRANT ALTER TO [loggingUser];'] }
        let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT' }

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
      let(:should_contain_command) { ['USE [loggingDb];'] }

      it_behaves_like 'compile'
    end

    context 'with_grant_option =>' do
      describe 'true' do
        let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT-WITH_GRANT_OPTION' }
        let(:additional_params) { { with_grant_option: true } }
        let(:should_contain_command) do
          [
            "IF @perm_state != 'GRANT_WITH_GRANT_OPTION'",
            'GRANT SELECT TO [loggingUser] WITH GRANT OPTION;',
          ]
        end
        let(:should_not_contain_command) do
          [
            'REVOKE GRANT OPTION FOR SELECT FROM [loggingUser];',
          ]
        end
        let(:should_contain_onlyif) { ["IF @perm_state != 'GRANT_WITH_GRANT_OPTION'"] }

        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql without_command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end

      describe 'false' do
        let(:should_contain_command) do
          [
            "IF @perm_state != 'GRANT'",
            'GRANT SELECT TO [loggingUser];',
            'REVOKE GRANT OPTION FOR SELECT TO [loggingUser] CASCADE;',
            "IF 'GRANT_WITH_GRANT_OPTION' = ISNULL(",
          ]
        end
        let(:should_contain_onlyif) { ["IF @perm_state != 'GRANT'"] }

        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end
    end
  end

  context 'command syntax' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-GRANT' }
      let(:params) do
        {
          user: 'loggingUser',
          permissions: ['SELECT'],
          database: 'loggingDb',
        }
      end

      describe '' do
        let(:should_contain_command) do
          [
            'USE [loggingDb];',
            'GRANT SELECT TO [loggingUser];',
            %r{DECLARE @perm_state varchar\(250\), @error_msg varchar\(250\)},
            %r{SET @permission = 'SELECT'},
            %r{SET @perm_state = ISNULL\(\n\s+\(SELECT perm.state_desc FROM sys\.database_principals princ\n\s+JOIN sys\.},
            %r{JOIN sys\.database_permissions perm ON perm\.grantee_principal_id = princ.principal_id\n\s+WHERE},
            %r{WHERE princ\.type in \('U','S','G'\) AND name = 'loggingUser' AND permission_name = @permission\),\n\s+'REVOKE'\)\s+;},
            %r{SET @error_msg = 'EXPECTED user \[loggingUser\] to have permission \[' \+ @permission \+ '\] with GRANT but got ' \+ @perm_state;},
            %r{IF @perm_state != 'GRANT'\n\s+THROW 51000, @error_msg, 10},
          ]
        end

        it_behaves_like 'sqlserver_tsql command'
      end
    end
  end
end
