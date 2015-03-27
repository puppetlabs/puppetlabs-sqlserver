require 'spec_helper_acceptance'
require File.expand_path(File.join(File.dirname(__FILE__), 'sqlserver_sqlcmd_examples.rb'))


%w(2012 2014).each do |version|
  host = get_host_for(version)
  RSpec.describe "sqlserver::login #{version}", :node => host do
    include_context 'sqlcmd_context'
    let(:host) { host }

    describe 'create a sql login' do
      create_login = <<-MANIFEST
      sqlserver::config{'MSSQLSERVER':
        admin_user => 'sa',
        admin_pass => 'Pupp3t1@',
      }
      sqlserver::login{'create logging user':
        login => 'loggingUser',
        password => 'Pupp3t1@',
        }
      MANIFEST
      let(:query) { "SELECT name FROM sys.server_principals WHERE name = 'loggingUser'" }
      let(:result) { "loggingUser" }
      it 'should create login [loggingUser]' do
        apply_manifest_on(host, create_login)
      end
      it_should_behave_like 'query result'
    end
  end
end
