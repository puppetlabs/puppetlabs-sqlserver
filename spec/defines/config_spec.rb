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

  context 'without admin_pass' do
    let(:params) { {
      :instance_name => 'MSSQLSERVER',
      :admin_user => 'sa',
    } }

    if Puppet.version < '4.3.0'
      let(:error_message) { /Must pass admin_pass to Sqlserver::Config/ }
    else
      let(:error_message) { /expects a value for parameter 'admin_pass'/ }
    end

    it {
      should_not compile
      expect { catalogue }.to raise_error(Puppet::Error, error_message)
      }
  end

  context 'without admin_user' do
    let(:params) { {
      :instance_name => 'MSSQLSERVER',
      :admin_pass => 'Pupp3t1@',
    } }


    if Puppet.version < '4.3.0'
      let(:error_message) { /Must pass admin_user to Sqlserver::Config/ }
    else
      let(:error_message) { /expects a value for parameter 'admin_user'/ }
    end

    it {
      should_not compile
      expect { catalogue }.to raise_error(Puppet::Error, error_message)
      }
  end
end
