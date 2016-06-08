require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::config', :type => :define do
  let(:title) { 'MSSQLSERVER' }
  let(:facts) { {:osfamily => 'windows', :platform => 'windows', :puppet_vardir => 'C:/ProgramData/PuppetLabs/puppet/var'} }

  describe 'compile' do
    let(:params) { {
      :instance_name => 'MSSQLSERVER',
      :admin_user => 'sa',
      :admin_pass => 'Pupp3t1@',
    } }

    it {
      should_not contain_file('C:/ProgramData/PuppetLabs/puppet/var/cache/sqlserver/.MSSQLSERVER.cfg')
      should_not contain_file('C:/ProgramData/PuppetLabs/puppet/var/cache/sqlserver')
    }
  end

  context 'SQL Server based authentication' do
    context 'without admin_pass' do
      let(:params) { {
        :instance_name => 'MSSQLSERVER',
        :admin_user => 'sa',
        :admin_login_type => 'SQL_LOGIN',
      } }

      let(:error_message) { /expects admin_pass to be set for a admin_login_type of SQL_LOGIN/ }

      it {
        should_not compile
        expect { catalogue }.to raise_error(Puppet::Error, error_message)
        }
    end

    context 'without admin_user' do
      let(:params) { {
        :instance_name => 'MSSQLSERVER',
        :admin_pass => 'Pupp3t1@',
        :admin_login_type => 'SQL_LOGIN',
      } }

      let(:error_message) { /expects admin_user to be set for a admin_login_type of SQL_LOGIN/ }

      it {
        should_not compile
        expect { catalogue }.to raise_error(Puppet::Error, error_message)
        }
    end
  end

  context 'SQL Server based authentication' do
    context 'with admin_user' do
      let(:params) { {
        :instance_name => 'MSSQLSERVER',
        :admin_user => 'sa',
        :admin_login_type => 'WINDOWS_LOGIN',
      } }

      let(:error_message) { /expects admin_user to be empty for a admin_login_type of WINDOWS_LOGIN/ }

      it {
        should_not compile
        expect { catalogue }.to raise_error(Puppet::Error, error_message)
        }
    end

    context 'with admin_pass' do
      let(:params) { {
        :instance_name => 'MSSQLSERVER',
        :admin_pass => 'Pupp3t1@',
        :admin_login_type => 'WINDOWS_LOGIN',
      } }

      let(:error_message) { /expects admin_pass to be empty for a admin_login_type of WINDOWS_LOGIN/ }

      it {
        should_not compile
        expect { catalogue }.to raise_error(Puppet::Error, error_message)
        }
    end
  end
end
