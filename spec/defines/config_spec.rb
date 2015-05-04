require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'manifest_shared_examples.rb'))

RSpec.describe 'sqlserver::config', :type => :define do
  let(:title) { 'MSSQLSERVER' }
  let(:params) { {
      :instance_name => 'MSSQLSERVER',
      :admin_user => 'sa',
      :admin_pass => 'Pupp3t1@',
  } }
  let(:facts) { {:osfamily => 'windows', :platform => :windows} }
  describe 'compile' do
    it {
      should contain_file('C:/Program Files/Microsoft SQL Server/.puppet/.MSSQLSERVER.cfg')
      should contain_file('C:/Program Files/Microsoft SQL Server/.puppet')
    }
  end
end
