require 'spec_helper_acceptance'

require File.expand_path(File.join(File.dirname(__FILE__), 'sqlserver_instance_shared_context.rb'))

RSpec.describe 'sqlserver_instance' do
  include_context 'sqlserver_instance_context'

  %w(2012 2014).each do |version|
    beaker_host = get_host_for(version)
    describe "Install #{version} SQL Instance", :node => beaker_host do
      let(:beaker_host) { beaker_host }
      let(:sqlserver_version) { version }
      let(:sqlserver_iso) { version =~ /2012/ ? SQL_2012_ISO : SQL_2014_ISO }
      it_behaves_like 'server_prefetch'
      it_behaves_like 'install sqlserver'
      it_behaves_like 'services installed'
      it_behaves_like 'packages installed',
                      ["SQL Server #{version} Database Engine Services",
                       "SQL Server #{version} Data Quality Service",
                       "SQL Server #{version} Full text search",
                       "SQL Server #{version} Database Engine Shared"]

      %w(backupdir datadir tempdbdir).each do |file|
        describe file("C:\\MSSQLSERVER\\#{file}") do
          it { should be_directory }
        end
      end
    end
  end
end
