require 'spec_helper'

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mssql_install_context.rb'))

provider_class = Puppet::Type.type(:mssql_instance).provider(:mssql)

RSpec.describe provider_class do
  subject { provider_class }

  shared_examples 'run' do |args, munged_values = {}|
    it {
      execute_args = args.merge(munged_values)
      @resource = Puppet::Type::Mssql_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_powershell_call(subject)
      stub_source_which_call args[:source]

      cmd_args = ["#{execute_args[:source]}/setup.exe",
                  "/ACTION=install",
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/INSTANCENAME=#{execute_args[:name]}",
                  "/FEATURES=#{execute_args[:features].join(',')}",]
      (execute_args.keys - %w(ensure loglevel features name source sql_sysadmin_accounts sql_security_mode).map(&:to_sym)).sort.collect do |key|
        cmd_args << "/#{key.to_s.gsub(/_/, '').upcase}=\"#{@resource[key]}\""
      end
      if execute_args[:sql_security_mode]
        cmd_args << "/SECURITYMODE=SQL"
      end
      cmd_args << "/SQLSYSADMINACCOUNTS=#{ Array.new(@resource[:sql_sysadmin_accounts]).collect { |account| "\"#{account}\"" }.join(' ')}"
      Puppet::Util::Execution.stubs(:execute).with(cmd_args.compact).returns(0)
      @provider.create
    }
  end

  context 'it should provide the correct command default command' do
    include_context 'install_arguments'
    munged = {:features => Array.new(@install_args[:features])}
    munged[:features].delete('SQL')
    munged[:features] += %w(DQ FullText Replication SQLEngine)

    munged[:features].sort!
    it_should_behave_like 'run', @install_args, munged
  end

  context 'it should expand the SQL features on munge' do
    include_context 'install_arguments'
    @install_args[:features] = %w(SQL)
    munged = {:features => %w(DQ FullText Replication SQLEngine)}
    it_should_behave_like 'run', @install_args, munged
  end

  shared_examples 'destroy' do |args, installed_features|
    it {
      @resource = Puppet::Type::Mssql_instance.new(args)
      @provider = provider_class.new(@resource)

      stub_source_which_call args[:source]
      @provider.expects(:current_installed_features).returns(installed_features)
      cmd_args = ["#{args[:source]}/setup.exe",
                  "/ACTION=uninstall",
                  '/Q',
                  '/IACCEPTSQLSERVERLICENSETERMS',
                  "/INSTANCENAME=#{args[:name]}",
                  "/FEATURES=#{installed_features.join(',')}",]
      Puppet::Util::Execution.stubs(:execute).with(cmd_args.compact).returns(0)
      @provider.destroy
    }
  end

  context 'it should uninstall' do
    describe 'installed features' do
      feature_params = {
          :name => 'MYSQLSERVER',
          :source => 'C:\myinstallexecs',
          :features => []
      }
      installed_features = %w(SQLEngine Replication)
      it_should_behave_like 'destroy', feature_params, installed_features
    end
    describe 'installed features even if provided features' do
      feature_params = {
          :name => 'MYSQLSERVER',
          :source => 'C:\myinstallexecs',
          :features => ['SQL']
      }
      installed_features = %w(SQLEngine Replication)
      it_should_behave_like 'destroy', feature_params, installed_features
    end
  end
end
