require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'manifest_shared_examples.rb'))

describe 'sqlserver::user::permission' do
  let(:facts) { {:osfamily => 'windows'} }
  context 'validation errors' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-SELECT' }
    end
    context 'user =>' do
      let(:params) { {
          :permission => 'SELECT',
          :database => 'loggingDb',
      } }
      let(:raise_error_check) { 'User must be between 1 and 128 characters' }
      describe 'missing' do
        let(:raise_error_check) { 'Must pass user to Sqlserver::User::Permission[myTitle]' }
        it_behaves_like 'validation error'
      end
      describe 'empty' do
        let(:additional_params) { {:user => ''} }
        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { {:user => random_string_of_size(129)} }
        it_behaves_like 'validation error'
      end
    end
    context 'permission' do
      let(:params) { {
          :user => 'loggingUser',
          :database => 'loggingDb',
      } }
      let(:raise_error_check) { 'Permission must be between 4 and 128 characters' }
      describe 'empty' do
        let(:additional_params) { {:permission => ''} }
        it_behaves_like 'validation error'
      end
      describe 'under limit' do
        let(:additional_params) { {:permission => random_string_of_size(3, false)} }
        it_behaves_like 'validation error'
      end
      describe 'over limit' do
        let(:additional_params) { {:permission => random_string_of_size(129, false)} }
        it_behaves_like 'validation error'
      end
    end
    context 'state =>' do
      let(:params) { {
          :permission => 'SELECT',
          :database => 'loggingDb',
          :user => 'loggingUser'
      } }
      describe 'invalid' do
        let(:additional_params) { {:state => 'invalide'} }
        let(:raise_error_check) { "State can only be of 'GRANT', 'REVOKE' or 'DENY' you passed invalide" }
        it_behaves_like 'validation error'
      end
    end
    context 'with_grant_option => ' do
      let(:params) { {
          :permission => 'SELECT',
          :database => 'loggingDb',
          :user => 'loggingUser',

      } }
      describe 'true AND state => DENY' do
        let(:additional_params) { {:with_grant_option => true, :state => 'DENY'} }
        let(:raise_error_check) { "Can not use with_grant_option and state DENY, must be 'GRANT' " }
        it_behaves_like 'validation error'
      end
      describe 'invalid' do
        let(:additional_params) { {:with_grant_option => 'invalid'} }
        let(:raise_error_check) { '"invalid" is not a boolean' }
        it_behaves_like 'validation error'
      end
    end
  end
  context 'successfully' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-SELECT' }
      let(:params) { {
          :user => 'loggingUser',
          :permission => 'SELECT',
          :database => 'loggingDb',
      } }
    end
    %w(revoke grant deny).each do |state|
      context "state => '#{state}'" do
        let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-SELECT' }
        let(:should_contain_command) { ["#{state.upcase} SELECT TO [loggingUser];", 'USE [loggingDb];'] }
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
        let(:additional_params) { {:permission => permission} }
        let(:sqlserver_tsql_title) { "user-permissions-MSSQLSERVER-loggingDb-loggingUser-#{permission.upcase}" }
        let(:should_contain_command) { ['USE [loggingDb];'] }
        it_behaves_like 'sqlserver_tsql command'
      end
      describe 'alter' do
        let(:additional_params) { {:permission => 'ALTER'} }
        let(:should_contain_command) { ['USE [loggingDb];', 'GRANT ALTER TO [loggingUser];'] }
        let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-ALTER' }
        it_behaves_like 'sqlserver_tsql command'
      end
    end

    describe 'Minimal Params' do
      let(:pre_condition) { <<-EOF
      define sqlserver::config{}
      sqlserver::config {'MSSQLSERVER': }
      EOF
      }
      let(:should_contain_command) { ['USE [loggingDb];'] }
      it_behaves_like 'compile'
    end

    context 'with_grant_option =>' do
      describe 'true' do
        let(:additional_params) { {:with_grant_option => true} }
        let(:should_contain_command) { [
            "IF @perm_state != 'GRANT_WITH_GRANT_OPTION'",
            'GRANT SELECT TO [loggingUser] WITH GRANT OPTION;',
        ] }
        let(:should_not_contain_command) { [
            'REVOKE GRANT OPTION FOR SELECT FROM [loggingUser];'] }
        let(:should_contain_onlyif) { ["IF @perm_state != 'GRANT_WITH_GRANT_OPTION'",] }
        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql without_command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end
      describe 'false' do
        let(:should_contain_command) { [
            "IF @perm_state != 'GRANT'",
            'GRANT SELECT TO [loggingUser];',
            'REVOKE GRANT OPTION FOR SELECT TO [loggingUser] CASCADE;',
            "IF 'GRANT_WITH_GRANT_OPTION' = ISNULL(",
        ] }

        let(:should_contain_onlyif) { ["IF @perm_state != 'GRANT'",] }
        it_behaves_like 'sqlserver_tsql command'
        it_behaves_like 'sqlserver_tsql onlyif'
      end
    end
  end

  context 'command syntax' do
    include_context 'manifests' do
      let(:title) { 'myTitle' }
      let(:sqlserver_tsql_title) { 'user-permissions-MSSQLSERVER-loggingDb-loggingUser-SELECT' }
      let(:params) { {
          :user => 'loggingUser',
          :permission => 'SELECT',
          :database => 'loggingDb',
      } }
      describe '' do
        let(:should_contain_command) { [
            'USE [loggingDb];',
            'GRANT SELECT TO [loggingUser];',
            /DECLARE @perm_state varchar\(250\)/,
            /SET @perm_state = ISNULL\(\n\s+\(SELECT perm.state_desc FROM sys\.database_principals princ\n\s+JOIN sys\./,
            /JOIN sys\.database_permissions perm ON perm\.grantee_principal_id = princ.principal_id\n\s+WHERE/,
            /WHERE princ\.type in \('U','S','G'\) AND name = 'loggingUser' AND permission_name = 'SELECT'\),\n\s+'REVOKE'\)\s+;/,
            /DECLARE @error_msg varchar\(250\);\nSET @error_msg = 'EXPECTED user \[loggingUser\] to have permission \[SELECT\] with GRANT but got ' \+ @perm_state;/,
            /IF @perm_state != 'GRANT'\n\s+THROW 51000, @error_msg, 10/
        ] }
        it_behaves_like 'sqlserver_tsql command'
      end
    end
  end

end
